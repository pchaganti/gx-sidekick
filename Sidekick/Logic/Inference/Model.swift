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
	
	/// The content of the message being generated, of type `String`
	@Published var pendingMessage: String = ""
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
		self.pendingMessage = ""
		self.sentConversationId = id
	}
	
	/// Function to flag that conversaion naming has begun
	func indicateStartedNamingConversation() {
		// Reset pending message
		self.pendingMessage = ""
		self.status = .generatingTitle
	}
	
	/// Function to flag that a background task has begun
	func indicateStartedBackgroundTask() {
		// Reset pending message
		self.pendingMessage = ""
		self.status = .backgroundTask
	}
	
	/// Function to flag that querying has begun
	func indicateStartedQuerying() {
		// Reset pending message
		self.pendingMessage = ""
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
		self.pendingMessage = ""
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
                        let displayedCount = self.pendingMessage.count
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
			self.pendingMessage,
			response!.usage?.total_tokens
		)
		// Update display
		self.pendingMessage = ""
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
		similarityIndex: SimilarityIndex? = nil,
		handleResponseUpdate: @escaping (String, String) -> Void,
		increment: Int
	) async throws -> LlamaServer.CompleteResponse {
		// Handle initial response
		let initialResponse = try await getInitialResponse(
			mode: mode,
            canReachRemoteServer: canReachRemoteServer,
			messages: messagesWithSources,
			similarityIndex: similarityIndex,
			handleResponseUpdate: handleResponseUpdate,
			increment: increment
		)
		// Return if code interpreter is disabled
		if !Settings.useCodeInterpreter {
			return initialResponse
		}
		// Return if code interpreter wasn't used
		guard initialResponse.containsInterpreterCall,
			  let jsCodeRange = initialResponse.javascriptCodeRange else {
			return initialResponse
		}
		// Handle code interpreter response
		return try await self.handleCodeInterpreterResponse(
            canReachRemoteServer: canReachRemoteServer,
			initialResponse: initialResponse,
			jsCodeRange: jsCodeRange,
			messages: messagesWithSources,
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
			similarityIndex: similarityIndex
		) { partialResponse in
			DispatchQueue.main.async {
				updateResponse += partialResponse
				let shouldUpdate = updateResponse.count >= increment ||
				self.pendingMessage.count < increment
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
	
	/// Function to run code if model calls the `run_javascript` tool
	private func handleCodeInterpreterResponse(
        canReachRemoteServer: Bool,
		initialResponse: LlamaServer.CompleteResponse,
		jsCodeRange: Range<String.Index>,
		messages: [Message.MessageSubset],
		similarityIndex: SimilarityIndex?,
		handleResponseUpdate: @escaping (
			String, // Full message
			String // Delta
		) -> Void = { _, _ in },
		increment: Int
	) async throws -> LlamaServer.CompleteResponse {
		// Set status
		self.status = .usingInterpreter
		self.pendingMessage = ""
		// Execute JavaScript
		let (jsCode, jsResult, _) = try await executeJavaScriptWithRetry(
            canReachRemoteServer: canReachRemoteServer,
			initialCode: String(initialResponse.text[jsCodeRange]),
			originalMessages: messages,
			similarityIndex: similarityIndex
		)
		// Switch status to show stream for final answer
		self.status = .processing
		// If the JavaScript was valid, return rephrased result
		if jsCode != nil && jsResult != nil {
			var rephrasedResponse = try await rephraseResult(
                canReachRemoteServer: canReachRemoteServer,
				initialResponse: initialResponse,
				increment: increment,
				jsCode: jsCode,
				jsResult: jsResult,
				messages: messages,
				handleResponseUpdate: handleResponseUpdate
			)
			rephrasedResponse.jsCode = jsCode
			rephrasedResponse.usedCodeInterpreter = true
			return rephrasedResponse
		} else {
			// Else, fall back on one-shot answer
			let response: LlamaServer.CompleteResponse = try await self.mainModelServer.getChatCompletion(
				mode: .contextAwareAgent,
                canReachRemoteServer: canReachRemoteServer,
                messages: messages,
				similarityIndex: similarityIndex
			)
			return response
		}
	}
	
	/// Function to try running JavaScript code for code interpreter, and retry with fixes
	private func executeJavaScriptWithRetry(
        canReachRemoteServer: Bool,
		initialCode: String,
		originalMessages: [Message.MessageSubset],
		similarityIndex: SimilarityIndex?
	) async throws -> (
		jsCode: String?,
		jsResult: String?,
		messages: [Message.MessageSubset]
	) {
		// Initialize variables for multi-step interpreter
		var jsCode = initialCode
		var messages = originalMessages
		var jsResult: String?
		// Loop `n` times until success
		let loopLimit: Int = 5
		for _ in 0..<loopLimit {
			do {
				// Execute JavaScript
				jsResult = try JavaScriptRunner.executeJavaScript(jsCode)
				break
			} catch let error as JavaScriptRunner.JSError {
				// Try to get the model to fix the code
				let errorMessage = Message(
					text: "The JavaScript code failed with an error of \"\(error)\"",
					sender: .user
				)
                let errorMessageSubset = await Message.MessageSubset(
                    message: errorMessage
                )
				messages.append(errorMessageSubset)
                let response = try await self.mainModelServer.getChatCompletion(
					mode: .chat,
                    canReachRemoteServer: canReachRemoteServer,
					messages: messages,
					similarityIndex: similarityIndex
				)
				jsCode = response.javascriptCodeRange.map { String(response.text[$0]) } ?? ""
				if jsCode.isEmpty { break }
			}
		}
		return (jsCode, jsResult, messages)
	}
	
	/// Function to rephrase code interpreter result
	private func rephraseResult(
        canReachRemoteServer: Bool,
		initialResponse: LlamaServer.CompleteResponse,
		increment: Int,
		jsCode: String?,
		jsResult: String?,
		messages: [Message.MessageSubset],
		handleResponseUpdate: @escaping (
			String, // Full message
			String // Delta
		) -> Void
	) async throws -> LlamaServer.CompleteResponse {
		// Formulate messages
		let initialResponseMessage = Message(
			text: initialResponse.text,
			sender: .user
		)
		let initialResponseMessageSubset: Message.MessageSubset = await Message.MessageSubset(
			message: initialResponseMessage
		)
		let rephraseMessage = Message(
			text: """
  The JavaScript code `\(jsCode ?? "Error")` produced the result below:
  
  \(jsResult ?? "Error")
  
  Explain how the question above would be answered without code, then end with the answer calculated and verified by the JavaScript you wrote. 
  """,
			sender: .user
		)
		let rephraseMessageSubset: Message.MessageSubset = await Message.MessageSubset(
			message: rephraseMessage
		)
		let updatedMessages: [Message.MessageSubset] = messages + [
			initialResponseMessageSubset,
			rephraseMessageSubset
		]
		// Submit for completion
		var updateResponse: String = ""
        return try await self.mainModelServer.getChatCompletion(
			mode: .contextAwareAgent,
            canReachRemoteServer: canReachRemoteServer,
			messages: updatedMessages
		) { partialResponse in
			DispatchQueue.main.async {
				// Update response
				updateResponse += partialResponse
				// Display if large update
				let updateCount: Int = updateResponse.count
				let displayedCount = self.pendingMessage.count
				if updateCount >= increment || displayedCount < increment {
					self.handleCompletionProgress(
						partialResponse: updateResponse,
						handleResponseUpdate: handleResponseUpdate
					)
					updateResponse = ""
				}
			}
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
		let fullMessage: String = (self.pendingMessage + partialResponse)
		handleResponseUpdate(
			fullMessage,
			partialResponse
		)
		self.pendingMessage = fullMessage
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
		if self.status != .processing, self.status != .coldProcessing {
			return
		}
		await self.mainModelServer.interrupt()
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
		case usingInterpreter
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
