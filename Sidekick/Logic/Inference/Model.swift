//
//  Model.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import FSKit_macOS
import SimilaritySearchKit

@MainActor
public class Model: ObservableObject {
	
	init(
		systemPrompt: String
	) {
		// Make sure bookmarks are loaded
		let _ = Bookmarks.shared
		// Set system prompt
		self.systemPrompt = systemPrompt + "\n\n" + InferenceSettings.useSourcesPrompt
		// Get model and context length
		guard let modelPath: String = Settings.modelUrl?.posixPath else {
			fatalError("Could not find modelUrl")
		}
		// Init `llama-server`
		self.llama = LlamaServer(
			modelPath: modelPath,
			systemPrompt: systemPrompt
		)
	}
	
	var id: UUID = UUID()
	
	/// Property for the system prompt
	private var systemPrompt: String
	/// Function that returns the system prompt
	func getSystemPrompt() -> String {
		systemPrompt
	}
	
	/// Function to update to the default system prompt
	public func updateSystemPrompt(_ systemPrompt: String) async {
		self.systemPrompt = systemPrompt + "\n\n" + InferenceSettings.useSourcesPrompt
		// Get model path
		guard let modelPath: String = Settings.modelUrl?.posixPath else {
			fatalError("Could not find modelUrl")
		}
		await self.llama.stopServer()
		self.llama = LlamaServer(
			modelPath: modelPath,
			systemPrompt: self.systemPrompt
		)
	}
	
	// Dialogue is the dialogue from prompt without system prompt / internal thoughts
	@Published var pendingMessage = ""
	@Published var status: Status = .cold
	@Published var sentConversationId: UUID? = nil
	
	// Each `Model` object runs its own server
	var llama: LlamaServer
	
	/// Computed property returning if the model is processing
	var isProcessing: Bool {
		return status == .processing || status == .coldProcessing
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
		similarityIndex: SimilarityIndex?
	) async throws -> LlamaServer.CompleteResponse {
		// Set flag
		let preQueryStatus: Status = self.status
		self.status = .querying
		let lastIndex: Int = messages.count - 1
		let messagesWithSources: [Message.MessageSubset] = await messages
			.enumerated()
			.asyncMap { index, message in
				return await Message.MessageSubset(
					message: message,
					similarityIndex: index != lastIndex ? nil : similarityIndex
				)
			}
		// Respond to prompt
		if preQueryStatus == .cold {
			status = .coldProcessing
		} else {
			status = .processing
		}
		let response = try await llama.chat(
			messages: messagesWithSources,
			similarityIndex: similarityIndex
		) { partialResponse in
			DispatchQueue.main.async {
				self.handleCompletionProgress(partialResponse: partialResponse)
			}
		}
		// When prompt finishes...
		pendingMessage = response.text
		status = .ready
		self.sentConversationId = nil
		return response
	}
	
	/// Function to handle response update
	func handleCompletionProgress(partialResponse: String) {
		self.pendingMessage += partialResponse
	}
	
	/// Function to interrupt `llama-server` generation
	func interrupt() async {
		if status != .processing, status != .coldProcessing { return }
		await llama.interrupt()
	}
	
	public enum Status: String {
		case cold
		case coldProcessing
		case querying
		case ready  // Ready
		case processing
	}
	
}
