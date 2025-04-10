//
//  Model.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import FSKit_macOS
import OSLog
import SimilaritySearchKit
import SwiftUI

/// An object which abstracts LLM inference
@MainActor
public class Model: ObservableObject {
	
	/// A `Logger` object for the `Model` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: Model.self)
	)
	
	/// Initializes the ``Model`` object
	/// - Parameter systemPrompt: The system prompt given to the model
	init(
		systemPrompt: String
	) {
		// Make sure bookmarks are loaded
		let _ = Bookmarks.shared
		// Set system prompt
		self.systemPrompt = systemPrompt
		// Init LlamaServer objects
		self.mainModelServer = LlamaServer(
            modelType: .regular,
            systemPrompt: systemPrompt
		)
        self.workerModelServer = LlamaServer(
            modelType: .worker
        )
        // Load models if not using remote server
        Task { [weak self] in
            guard let self = self else { return }
            let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
			do {
				if !InferenceSettings.useServer || !canReachRemoteServer {
					try await self.mainModelServer.startServer(
                        canReachRemoteServer: canReachRemoteServer
                    )
                    try await self.workerModelServer.startServer(
                        canReachRemoteServer: canReachRemoteServer
                    )
				}
			} catch {
				print("Error starting `llama-server`: \(error)")
			}
		}
	}
	
	/// Task where `llama-server` is launched
	private var startupTask: Task<Void, Never>?

	/// Static constant for the global ``Model`` object
	static public let shared: Model = .init(
		systemPrompt: InferenceSettings.systemPrompt
	)
    
    /// A `Bool` representing whether the remote server is accessible
    public var wasRemoteServerAccessible: Bool = false
    /// A `Date` representing when the remote server was less checked
    private var lastRemoteServerCheck: Date = .distantPast
	
	/// Property for the system prompt given to the LLM
	private var systemPrompt: String
	
	/// Function to set new system prompt, which controls model behaviour
	/// - Parameter systemPrompt: The system prompt to be set
	public func setSystemPrompt(
		_ systemPrompt: String
	) async {
		self.systemPrompt = systemPrompt
		await self.mainModelServer.setSystemPrompt(systemPrompt)
	}
	
	/// Function to refresh `llama-server` with the newly selected model
	public func refreshModel() async {
		// Restart servers if needed
        await self.stopServers()
		self.mainModelServer = LlamaServer(
            modelType: .regular,
			systemPrompt: self.systemPrompt
		)
        self.workerModelServer = LlamaServer(
            modelType: .worker
        )
		// Load model if needed
		let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
		if !InferenceSettings.useServer || !canReachRemoteServer {
			try? await self.mainModelServer.startServer(
                canReachRemoteServer: canReachRemoteServer
            )
            try? await self.workerModelServer.startServer(
                canReachRemoteServer: canReachRemoteServer
            )
		}
	}
	
	/// The message being generated
	@Published var pendingMessage: Message? = nil
    /// The pending message displayed to users
    public var displayedPendingMessage: Message {
        var text: String = ""
        var functionCalls: [FunctionCall] = self.pendingMessage?.functionCalls ?? []
        switch self.status {
            case .cold, .coldProcessing, .processing, .backgroundTask, .ready:
                if let pendingText = self.pendingMessage?.text {
                    text = pendingText
                } else {
                    text = String(localized: "Processing...")
                }
            case .querying:
                text = String(localized: "Searching...")
            case .generatingTitle:
                text = String(localized: "Generating title...")
            case .usingFunctions:
                if functionCalls.isEmpty {
                    // If no calls found
                    text = String(localized: "Calling functions...")
                }
                // Show progress
                if let pendingText = self.pendingMessage?.text {
                    text = pendingText
                }
        }
        return Message(
            text: text,
            sender: .assistant,
            functionCalls: functionCalls
        )
    }
    
	/// The status of `llama-server`, of type ``Model.Status``
	@Published var status: Status = .cold
	/// The id of the conversation where the message was sent, of type `UUID`
	@Published var sentConversationId: UUID? = nil
	
	/// A server fro the main model, of type ``LlamaServer``
	var mainModelServer: LlamaServer
    /// A server for the worker model, of type ``LlamaServer``
    var workerModelServer: LlamaServer
	
	/// Computed property returning if the model is processing, of type `Bool`
	var isProcessing: Bool {
		return status == .processing || status == .coldProcessing
	}
	
	/// Function to calculate the number of tokens in a piece of text
	public func countTokens(
		in text: String
	) async -> Int? {
        let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
		return try? await self.mainModelServer.tokenCount(
            in: text,
            canReachRemoteServer: canReachRemoteServer
        )
	}
	
	/// Function to set sent conversation ID
	func setSentConversationId(_ id: UUID) {
		// Reset pending message
		self.pendingMessage = nil
		self.sentConversationId = id
	}
	
	/// Function to flag that conversaion naming has begun
	func indicateStartedNamingConversation() {
		// Reset pending message
		self.pendingMessage = nil
		self.status = .generatingTitle
	}
	
	/// Function to flag that a background task has begun
	func indicateStartedBackgroundTask() {
		// Reset pending message
		self.pendingMessage = nil
		self.status = .backgroundTask
	}
	
	/// Function to flag that querying has begun
	func indicateStartedQuerying() {
		// Reset pending message
		self.pendingMessage = nil
		self.status = .querying
	}
	
	// Function for the main loop
	// listen -> respond -> update mental model and save checkpoint
	// we respond before updating to avoid a long delay after user input
	func listenThinkRespond(
		messages: [Message],
		modelType: ModelType,
		mode: Model.Mode,
		similarityIndex: SimilarityIndex? = nil,
		useWebSearch: Bool = false,
		useCanvas: Bool = false,
		canvasSelection: String? = nil,
		temporaryResources: [TemporaryResource] = [],
		handleResponseUpdate: @escaping (
			String, // Full message
			String // Delta
		) -> Void = { _, _ in },
		handleResponseFinish: @escaping (
			String, // Pending message
			String,  // Final message
			Int? // Tokens used
		) -> Void = { _, _, _ in }
	) async throws -> LlamaServer.CompleteResponse {
		// Reset pending message
		self.pendingMessage = nil
		// Set flag
		let preQueryStatus: Status = self.status
		if preQueryStatus.isForegroundTask {
			self.status = .querying
		}
        // Check if remote server is reachable
        let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
        // Formulate message subset
        let useServer: Bool = canReachRemoteServer && InferenceSettings.useServer
        let lastIndex: Int = messages.count - 1
        let messagesWithSources: [Message.MessageSubset] = await messages
            .enumerated()
            .asyncMap { index, message in
                return await Message.MessageSubset(
                    message: message,
                    similarityIndex: similarityIndex,
                    temporaryResources: temporaryResources,
                    shouldAddSources: (
                        index == lastIndex
                    ),
                    useMultimodalContent: LlamaServer.modelHasVision(
                        type: modelType,
                        usingRemoteModel: useServer
                    ),
                    useWebSearch: useWebSearch,
                    useCanvas: useCanvas,
                    canvasSelection: canvasSelection
                )
            }
        // Respond to prompt
        if self.status.isForegroundTask {
            if preQueryStatus == .cold {
                self.status = .coldProcessing
            } else {
                self.status = .processing
            }
        }
		// Declare variables for incremental update
		var updateResponse: String = ""
		let increment: Int = 3
		// Send different response based on mode
		var response: LlamaServer.CompleteResponse? = nil
        switch mode {
            case .`default`:
                if modelType == .worker {
                    do {
                        response = try await self.workerModelServer.getChatCompletion(
                            mode: mode,
                            canReachRemoteServer: canReachRemoteServer,
                            messages: messagesWithSources
                        ) { partialResponse in
                            DispatchQueue.main.async {
                                // Update response
                                updateResponse += partialResponse
                                self.handleCompletionProgress(
                                    partialResponse: partialResponse,
                                    handleResponseUpdate: handleResponseUpdate
                                )
                            }
                        }
                    } catch {
                        response = try await self.mainModelServer.getChatCompletion(
                            mode: mode,
                            canReachRemoteServer: canReachRemoteServer,
                            messages: messagesWithSources
                        ) { partialResponse in
                            DispatchQueue.main.async {
                                // Update response
                                updateResponse += partialResponse
                                self.handleCompletionProgress(
                                    partialResponse: partialResponse,
                                    handleResponseUpdate: handleResponseUpdate
                                )
                            }
                        }
                    }
                } else {
                    response = try await self.mainModelServer.getChatCompletion(
                        mode: mode,
                        canReachRemoteServer: canReachRemoteServer,
                        messages: messagesWithSources
                    ) { partialResponse in
                        DispatchQueue.main.async {
                            // Update response
                            updateResponse += partialResponse
                            self.handleCompletionProgress(
                                partialResponse: partialResponse,
                                handleResponseUpdate: handleResponseUpdate
                            )
                        }
                    }
                }
            case .chat:
                response = try await self.getChatResponse(
                    mode: mode,
                    modelType: modelType,
                    canReachRemoteServer: canReachRemoteServer,
                    messagesWithSources: messagesWithSources,
                    useWebSearch: useWebSearch,
                    similarityIndex: similarityIndex,
                    handleResponseUpdate: handleResponseUpdate,
                    increment: increment
                )
            case .contextAwareAgent:
                response = try await self.mainModelServer.getChatCompletion(
                    mode: mode,
                    canReachRemoteServer: canReachRemoteServer,
                    messages: messagesWithSources,
                    similarityIndex: similarityIndex
                ) { partialResponse in
                    DispatchQueue.main.async {
                        // Update response
                        updateResponse += partialResponse
                        // Display if large update
                        let updateCount: Int = updateResponse.count
                        let displayedCount = self.pendingMessage?.text.count ?? 0
                        if updateCount >= increment || displayedCount < increment {
                            self.handleCompletionProgress(
                                partialResponse: partialResponse,
                                handleResponseUpdate: handleResponseUpdate
                            )
                            updateResponse = ""
                        }
                    }
                }
        }
		// Handle response finish
		handleResponseFinish(
			response!.text,
            self.pendingMessage?.text ?? "",
			response!.usage?.total_tokens
		)
		// Update display
		self.pendingMessage = nil
		self.status = .ready
		Self.logger.notice("Finished responding to prompt")
		return response!
	}
	
	/// Function to get response for chat
	private func getChatResponse(
		mode: Model.Mode,
		modelType: ModelType,
        canReachRemoteServer: Bool,
		messagesWithSources: [Message.MessageSubset],
        useWebSearch: Bool,
		similarityIndex: SimilarityIndex? = nil,
		handleResponseUpdate: @escaping (String, String) -> Void,
		increment: Int
	) async throws -> LlamaServer.CompleteResponse {
		// Handle initial response
		let initialResponse = try await getInitialResponse(
			mode: mode,
            canReachRemoteServer: canReachRemoteServer,
			messages: messagesWithSources,
            useWebSearch: useWebSearch,
			similarityIndex: similarityIndex,
			handleResponseUpdate: handleResponseUpdate,
			increment: increment
		)
		// Return if functions are disabled
        if !Settings.useFunctions {
			return initialResponse
		}
		// Return if no function call
        guard let functionCall = initialResponse.functionCall else {
			return initialResponse
		}
		// Run agent in a loop
        return try await self.handleFunctionCall(
            canReachRemoteServer: canReachRemoteServer,
			initialResponse: initialResponse,
			messages: messagesWithSources,
            functionCall: functionCall,
            useWebSearch: useWebSearch,
			similarityIndex: similarityIndex,
			handleResponseUpdate: handleResponseUpdate,
			increment: increment
		)
	}
	
	/// Get the intial response to a chatbot query
	private func getInitialResponse(
		mode: Model.Mode,
        canReachRemoteServer: Bool,
		messages: [Message.MessageSubset],
        useWebSearch: Bool,
		similarityIndex: SimilarityIndex?,
		handleResponseUpdate: @escaping (String, String) -> Void,
		increment: Int
	) async throws -> LlamaServer.CompleteResponse {
        let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
		var updateResponse = ""
        return try await self.mainModelServer.getChatCompletion(
			mode: mode,
            canReachRemoteServer: canReachRemoteServer,
			messages: messages,
            useWebSearch: useWebSearch,
			similarityIndex: similarityIndex
		) { partialResponse in
			DispatchQueue.main.async {
				updateResponse += partialResponse
				let shouldUpdate = updateResponse.count >= increment ||
                (self.pendingMessage?.text.count ?? 0 < increment)
				if shouldUpdate {
					self.handleCompletionProgress(
						partialResponse: updateResponse,
						handleResponseUpdate: handleResponseUpdate
					)
					updateResponse = ""
				}
			}
		}
	}
	
	/// Function to run code if model calls a function
	private func handleFunctionCall(
        canReachRemoteServer: Bool,
		initialResponse: LlamaServer.CompleteResponse,
		messages: [Message.MessageSubset],
        functionCall: FunctionCall,
        useWebSearch: Bool,
		similarityIndex: SimilarityIndex?,
		handleResponseUpdate: @escaping (
			String, // Full message
			String // Delta
		) -> Void = { _, _ in },
		increment: Int
	) async throws -> LlamaServer.CompleteResponse {
		// Set status
		self.status = .usingFunctions
		// Execute functions on a loop
        var messages: [Message.MessageSubset] = messages
        var maxIterations: Int = 15
        var response: LlamaServer.CompleteResponse? = initialResponse
        while maxIterations > 0, var functionCall = response?.functionCall {
            // Log function call
            let callJsonSchema: String = functionCall.getJsonSchema()
            Self.logger.info("Executing function call: \(callJsonSchema, privacy: .public)")
            // Display call to user
            let functionCalls = self.pendingMessage?.functionCalls ?? []
            withAnimation(.linear) {
                self.pendingMessage?.functionCalls = functionCalls + [functionCall]
                self.pendingMessage?.text = ""
            }
            // Call function
            var messageString: String? = nil
            do {
                // Run
                let result: String = try await functionCall.call() ?? "Function evaluated successfully"
                // Mark as succeeded
                functionCall.status = .succeeded
                functionCall.result = result
                // Formulate callback message
                messageString = """
Below is the result produced by the tool call: `\(callJsonSchema)`. If the tool call provides enough information to solve the user's query, organize the information into an answer. If the tool call did not provide enough information, try breaking down the user's query and finding information about its constituent parts. Else, call another tool to obtain more information or execute more actions.

```tool_call_result
\(result)
``` 
"""
            } catch {
                // Mark as failed
                functionCall.status = .failed
                functionCall.result = error.localizedDescription
                // Formulate callback message
                messageString = """
The function call `\(callJsonSchema)` failed, producing the error below.

```tool_call_error
\(error.localizedDescription)
```
"""
            }
            withAnimation(.linear) {
                self.pendingMessage?.functionCalls = functionCalls + [functionCall]
            }
            let message = Message(
                text: messageString!,
                sender: .user
            )
            let messageSubset = await Message.MessageSubset(
                message: message
            )
            messages.append(messageSubset)
            // Declare variable for incremental update
            var updateResponse: String = ""
            self.pendingMessage?.text = updateResponse
            // Get response
            response = try await self.mainModelServer.getChatCompletion(
                mode: .chat,
                canReachRemoteServer: canReachRemoteServer,
                messages: messages,
                useWebSearch: useWebSearch,
                similarityIndex: similarityIndex
            )  { partialResponse in
                DispatchQueue.main.async {
                    updateResponse += partialResponse
                    let shouldUpdate = updateResponse.count >= increment ||
                    (self.pendingMessage?.text.count ?? 0 < increment)
                    if shouldUpdate {
                        self.handleCompletionProgress(
                            partialResponse: updateResponse,
                            handleResponseUpdate: handleResponseUpdate
                        )
                        updateResponse = ""
                    }
                }
            }
            response?.functionCalls = functionCalls + [functionCall]
            // Increment counter & reset
            maxIterations -= 1
        }
        // Switch status to show stream for final answer
        self.status = .processing
        // Get reason for finishing
        let finishReason: FinishReason = maxIterations == 0 ? .maxIterationsReached : .noFunctionCall
        if finishReason == .noFunctionCall, let response = response {
            return response
        } else {
            // Else, fall back on one-shot answer
            Self.logger.error("Maximum number of function calls reached. Falling back to one-shot answer.")
            // Declare variable for incremental update
            var updateResponse: String = ""
            self.pendingMessage?.text = updateResponse
            // Get response
            var response: LlamaServer.CompleteResponse = try await self.mainModelServer.getChatCompletion(
                mode: .contextAwareAgent,
                canReachRemoteServer: canReachRemoteServer,
                messages: messages,
                similarityIndex: similarityIndex
            ) { partialResponse in
                DispatchQueue.main.async {
                    updateResponse += partialResponse
                    let shouldUpdate = updateResponse.count >= increment ||
                    (self.pendingMessage?.text.count ?? 0 < increment)
                    if shouldUpdate {
                        self.handleCompletionProgress(
                            partialResponse: updateResponse,
                            handleResponseUpdate: handleResponseUpdate
                        )
                        updateResponse = ""
                    }
                }
            }
            if let functionCalls = self.pendingMessage?.functionCalls {
                response.functionCalls = functionCalls
            }
            return response
        }
		// An enum of reasons for finishing
        enum FinishReason {
            case noFunctionCall, maxIterationsReached
        }
	}
	
	/// Function to handle response update
	func handleCompletionProgress(
		partialResponse: String,
		handleResponseUpdate: @escaping (
			String, // Full message
			String // Delta
		) -> Void
	) {
        // Assign if nil
        if self.pendingMessage == nil {
            self.pendingMessage = Message(text: "", sender: .assistant)
        }
        let fullMessage: String = (self.pendingMessage?.text ?? "") + partialResponse
		handleResponseUpdate(
			fullMessage,
			partialResponse
		)
        self.pendingMessage?.text = fullMessage
	}
    
    /// Function to check if the remote server is reachable
    /// - Returns: A `Bool` indicating if the server can be reached
    public func remoteServerIsReachable() async -> Bool {
        // Return false if server is unused
        if !InferenceSettings.useServer { return false }
        // Try to use cached result
        let lastPathChangeDate: Date = NetworkMonitor.shared.lastPathChange
        if self.lastRemoteServerCheck >= lastPathChangeDate {
            return self.wasRemoteServerAccessible
        }
        // Get last path change time
        // If using server, check connection on multiple endpoints
        let testEndpoints: [String] = [
            "/v1/models",
            "/v1/chat/completions"
        ]
        for testEndpoint in testEndpoints {
            let endpoint: String = InferenceSettings.endpoint.replacingSuffix(
                testEndpoint,
                with: ""
            ) + testEndpoint
            guard let endpointUrl: URL = URL(
                string: endpoint
            ) else {
                continue
            }
            if await endpointUrl.isAPIEndpointReachable(
                timeout: 1
            ) {
                // Cache result, then return
                self.wasRemoteServerAccessible = true
                self.lastRemoteServerCheck = Date.now
                Self.logger.info("Reached remote server at '\(InferenceSettings.endpoint, privacy: .public)'")
                return true
            }
        }
        // If fell through, cache and return false
        Self.logger.warning("Could not reach remote server at '\(InferenceSettings.endpoint, privacy: .public)'")
        self.wasRemoteServerAccessible = false
        self.lastRemoteServerCheck = Date.now
        return false
    }
	
    /// Function to stop servers
    func stopServers() async {
        await self.mainModelServer.stopServer()
        await self.workerModelServer.stopServer()
        self.status = .cold
    }
    
	/// Function to interrupt `llama-server` generation
	func interrupt() async {
        if !self.status.isWorking {
			return
		}
		await self.mainModelServer.interrupt()
        self.pendingMessage = nil
		self.status = .ready
	}
	
	/// An enum indicating the status of the server
	public enum Status: String {
		
		/// The inference server is inactive
		case cold
		/// The inference server is warming up
		case coldProcessing
		/// The inference server is currently processing a prompt
		case processing
		/// The system is searching in the selected profile's resources.
		case querying
		/// The system is generating a title
		case generatingTitle
		/// The system is running a background task
		case backgroundTask
		/// The system is using a code interpreter
		case usingFunctions
		/// The inference server is awaiting a prompt
		case ready
		
		/// A `Bool` representing if the server is at work
		public var isWorking: Bool {
			switch self {
				case .cold, .ready:
					return false
				default:
					return true
			}
		}
		
		/// A `Bool` representing if the server is running a foreground task
		public var isForegroundTask: Bool {
			switch self {
				case .backgroundTask, .generatingTitle:
					return false
				default:
					return true
			}
		}
		
	}
	
	/// An enum indicating how the server is to be used
	public enum Mode: String {
		
		/// Indicates the LLM is used as a chatbot, with extra features like resource lookup and code interpreter
		case chat
		/// Indicates the LLM is used with context aware agent, with features like resource lookup
		case contextAwareAgent
		/// Indicates the LLM is used for simple chat completion
		case `default`
		
	}
	
}
