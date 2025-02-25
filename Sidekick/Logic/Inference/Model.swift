//
//  Model.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import FSKit_macOS
import SimilaritySearchKit

/// An object which abstracts LLM inference
@MainActor
public class Model: ObservableObject {
	
	/// Initializes the ``Model`` object
	/// - Parameter systemPrompt: The system prompt given to the model
	init(
		systemPrompt: String
	) {
		// Make sure bookmarks are loaded
		let _ = Bookmarks.shared
		// Set system prompt
		self.systemPrompt = systemPrompt
		// Get model and context length
		guard let modelPath: String = Settings.modelUrl?.posixPath else {
			fatalError("Could not find modelUrl")
		}
		// Init `llama-server`
		self.llama = LlamaServer(
			modelPath: modelPath,
			systemPrompt: systemPrompt
		)
		// Load model
		Task {
			try? await self.llama.startServer()
		}
	}
	
	/// Static constant for the global ``Model`` object
	static public let shared: Model = .init(
		systemPrompt: InferenceSettings.systemPrompt
	)
	
	/// Property for the system prompt given to the LLM
	private var systemPrompt: String
	
	/// Function to set new system prompt, which controls model behaviour
	/// - Parameter systemPrompt: The system prompt to be set
	public func setSystemPrompt(
		_ systemPrompt: String
	) async {
		self.systemPrompt = systemPrompt
		await self.llama.setSystemPrompt(systemPrompt)
	}
	
	/// Function to refresh `llama-server` with the newly selected model
	public func refreshModel() async {
		// Get model path
		guard let modelPath: String = Settings.modelUrl?.posixPath else {
			fatalError("Could not find modelUrl")
		}
		await self.llama.stopServer()
		self.llama = LlamaServer(
			modelPath: modelPath,
			systemPrompt: self.systemPrompt
		)
		// Load model
		try? await self.llama.startServer()
	}
	
	/// The content of the message being generated, of type `String`
	@Published var pendingMessage: String = ""
	/// The status of `llama-server`, of type ``Model.Status``
	@Published var status: Status = .cold
	/// The id of the conversation where the message was sent, of type `UUID`
	@Published var sentConversationId: UUID? = nil
	
	/// Each `Model` object runs its own server, of type ``LlamaServer``
	var llama: LlamaServer
	
	/// Computed property returning if the model is processing, of type `Bool`
	var isProcessing: Bool {
		return status == .processing || status == .coldProcessing
	}
	
	/// Function to calculate the number of tokens in a piece of text
	public func countTokens(
		in text: String
	) async -> Int? {
		return try? await self.llama.tokenCount(in: text)
	}
	
	/// Function to flag that querying has begun
	func indicateStartedQuerying(
		sentConversationId: UUID
	) {
		self.pendingMessage = ""
		self.status = .querying
		self.sentConversationId = sentConversationId
	}
	
	// This is the main loop of the agent
	// listen -> respond -> update mental model and save checkpoint
	// we respond before updating to avoid a long delay after user input
	func listenThinkRespond(
		messages: [Message],
		mode: Model.Mode,
		similarityIndex: SimilarityIndex? = nil,
		useWebSearch: Bool = false,
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
		self.status = .querying
		let lastIndex: Int = messages.count - 1
		let messagesWithSources: [Message.MessageSubset] = await messages
			.enumerated()
			.asyncMap { index, message in
				return await Message.MessageSubset(
					message: message,
					similarityIndex: similarityIndex,
					shouldAddSources: (index == lastIndex),
					useWebSearch: useWebSearch,
					temporaryResources: temporaryResources
				)
			}
		// Respond to prompt
		if preQueryStatus == .cold {
			status = .coldProcessing
		} else {
			status = .processing
		}
		// Declare variables for incremental update
		var updateResponse: String = ""
		let increment: Int = 3
		// Send different response based on mode
		var response: LlamaServer.CompleteResponse? = nil
		switch mode {
			case .chat:
				response = try await llama.getCompletion(
					mode: mode,
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
								partialResponse: updateResponse,
								handleResponseUpdate: handleResponseUpdate
							)
							updateResponse = ""
						}
					}
				}
			case .default:
				response = try await llama.getCompletion(
					mode: mode,
					messages: messagesWithSources
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
		// Handle response finish
		handleResponseFinish(
			response!.text,
			self.pendingMessage,
			response!.usage?.total_tokens
		)
		// Update display
		self.pendingMessage = response!.text
		self.status = .ready
		self.sentConversationId = nil
		return response!
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
	
	/// Function to interrupt `llama-server` generation
	func interrupt() async {
		if self.status != .processing, self.status != .coldProcessing {
			return
		}
		await self.llama.interrupt()
	}
	
	/// An enum indicating the status of the server
	public enum Status: String {
		
		/// The inference server is inactive
		case cold
		/// The inference server is warming up
		case coldProcessing
		/// The system is searching in the selected profile's resources. This is only available when the ``Model.Mode`` is set to `chat`
		case querying
		/// The inference server is awaiting a prompt
		case ready
		/// The inference server is currently processing a prompt
		case processing
		
	}
	
	/// An enum indicating how the server is to be used
	public enum Mode: String {
		
		/// Indicates the LLM is used as a chatbot, with extra features like resource lookup
		case chat
		/// Indicates the LLM is used for simple chat completion
		case `default`
		
	}
	
}
