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
    @Published public var wasRemoteServerAccessible: Bool = false
    /// A `Date` representing when the remote server was less checked
    private var lastRemoteServerCheck: Date = .distantPast
    
    /// A `String` containing the name of the currently selected model
    public var selectedModelName: String? {
        // Check if remote model is accessible
        let useServer: Bool = InferenceSettings.useServer && self.wasRemoteServerAccessible
        // If using remote
        if useServer {
            // Get remote model name
            let remoteModelName: String = InferenceSettings.serverModelName
            if !remoteModelName.isEmpty {
                return remoteModelName
            }
        } else {
            // Else, return local model name
            if let localModelName: String = Settings.modelUrl?
                .deletingPathExtension()
                .lastPathComponent,
               !localModelName.isEmpty {
                return localModelName
            }
        }
        // If fell through, return nil
        return nil
    }
    /// A `String` containing the name of the currently selected worker model
    public var selectedWorkerModelName: String? {
        // Check if remote model is accessible
        let useServer: Bool = InferenceSettings.useServer && self.wasRemoteServerAccessible
        // If using remote
        if useServer {
            // Get remote model name
            let remoteModelName: String = InferenceSettings.serverWorkerModelName
            if !remoteModelName.isEmpty {
                return remoteModelName
            }
        } else {
            // Else, return local model name
            if let localModelName: String = InferenceSettings.workerModelUrl?
                .deletingPathExtension()
                .lastPathComponent,
               !localModelName.isEmpty {
                return localModelName
            }
        }
        // If fell through, return nil
        return nil
    }
    /// The currently selected model
    public var selectedModel: KnownModel? {
        guard let identifier = self.selectedModelName else { return nil }
        var model = KnownModel(identifier: identifier)
        if identifier.hasSuffix(":thinking") {
            model?.isReasoningModel = true
        }
        return model
    }
    /// A `Bool` representing whether the selected model can reason
    public var selectedModelCanReason: Bool? {
        return self.selectedModel?.isReasoningModel ?? selectedModelName?.hasSuffix(":thinking")
    }
    /// The currently selected worker model
    public var selectedWorkerModel: KnownModel? {
        guard let identifier = self.selectedWorkerModelName else { return nil }
        var model = KnownModel(identifier: identifier)
        if identifier.hasSuffix(":thinking") {
            model?.isReasoningModel = true
        }
        return model
    }
    /// A `Bool` representing whether the selected worker model can reason
    public var selectedWorkerModelCanReason: Bool? {
        return self.selectedWorkerModel?.isReasoningModel ?? selectedWorkerModelName?.hasSuffix(":thinking")
    }
    
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
    
    /// The current active  ``Agent``
    var agent: (any Agent)?
    
    /// The message being generated
    @Published var pendingMessage: Message? = nil
    /// The pending message displayed to users
    @MainActor
    public var displayedPendingMessage: Message {
        var text: String = ""
        let functionCalls: [FunctionCallRecord] = self.pendingMessage?.functionCallRecords ?? []
        switch self.status {
            case .cold, .coldProcessing, .processing, .backgroundTask, .ready:
                if let pendingText = self.pendingMessage?.text {
                    text = pendingText
                } else {
                    // Set default text
                    text = String(localized: "Processing...")
                    // Get model name
                    if let modelName: String = ChatParameters.getModelName(
                        modelType: .regular
                    ) {
                        // Determine if is reasoning model
                        if KnownModel.availableModels.contains(
                            where: { model in
                                let nameMatches: Bool = modelName.contains(
                                    model.primaryName
                                )
                                return nameMatches && model.isReasoningModel
                            }
                        ) {
                            text = String(localized: "Thinking...")
                        }
                    }
                }
            case .querying:
                text = String(localized: "Searching...")
            case .generatingTitle:
                text = String(localized: "Generating title...")
            case .usingFunctions:
                // If no calls found or if all calls are complete
                text = String(localized: "Calling functions...")
                // Show progress
                if let pendingText = self.pendingMessage?.text,
                   !pendingText.isEmpty {
                    text = pendingText
                }
            case .deepResearch:
                text = String(localized: "Preparing Deep Research...")
        }
        if var pendingMessage: Message = self.pendingMessage {
            pendingMessage.text = text
            pendingMessage.functionCallRecords = functionCalls
            return pendingMessage
        } else {
            return Message(
                text: text,
                sender: .assistant
            )
        }
    }
    /// A `View` containing the pending message
    public var pendingMessageView: some View {
        Group {
            switch self.displayedContentType {
                case .text, .indicator:
                    MessageView(
                        message: self.displayedPendingMessage,
                        shimmer: self.displayedContentType == .indicator
                    )
                    .id(self.displayedPendingMessage.id)
                case .preview:
                    self.agent?.preview ?? AnyView(EmptyView())
            }
        }
    }
    /// A `Bool` representing whether the text or an indicator is shown
    public var displayedContentType: DisplayedContentType {
        let hasText: Bool = {
            if let text = self.pendingMessage?.text {
                return !text.isEmpty
            }
            return false
        }()
        switch self.status {
            case .cold, .coldProcessing, .processing, .backgroundTask, .ready, .usingFunctions:
                return !hasText ? .indicator : .text
            case .deepResearch:
                return self.agent == nil ? .indicator : .preview
            case .querying, .generatingTitle:
                return .indicator
        }
    }
    /// Enum for content displayed
    public enum DisplayedContentType: CaseIterable {
        case indicator, text, preview
    }
    
    /// The status of `llama-server`, of type ``Model.Status``
    @Published var status: Status = .cold
    /// Function to mutate the status
    public func setStatus(_ newStatus: Status) {
        self.status = newStatus
    }
    
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
    
    /// Function to flag that Deep Research has begun
    func indicateStartedDeepResearch() {
        // Reset pending message
        self.pendingMessage = nil
        self.status = .deepResearch
    }
    
    /// Function for the main loop
    /// Listen -> respond -> update mental model and save checkpoint
    /// Stream response  to avoid a long delay after user input
    func listenThinkRespond(
        messages: [Message],
        modelType: ModelType,
        mode: Model.Mode,
        similarityIndex: SimilarityIndex? = nil,
        useWebSearch: Bool = false,
        useFunctions: Bool = false,
        functions: [AnyFunctionBox]? = nil,
        useCanvas: Bool = false,
        canvasSelection: String? = nil,
        temporaryResources: [TemporaryResource] = [],
        showPreview: Bool = false,
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
        if showPreview {
            self.pendingMessage = nil
        }
        // Set flag
        let preQueryStatus: Status = self.status
        if preQueryStatus.isForegroundTask {
            let isDeepResearching: Bool = self.status == .deepResearch
            self.status = (mode.isAgent || isDeepResearching) ? .deepResearch : .querying
        }
        // Check if remote server is reachable
        let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
        // Formulate message subset
        let useServer: Bool = canReachRemoteServer && InferenceSettings.useServer
        let lastIndex: Int = messages.count - 1
        let hasVision: Bool = LlamaServer.modelHasVision(
            type: modelType,
            usingRemoteModel: useServer
        )
        let messagesWithSources: [Message.MessageSubset] = await messages
            .enumerated()
            .asyncMap { index, message in
                return await Message.MessageSubset(
                    modelType: modelType,
                    usingRemoteModel: useServer,
                    message: message,
                    similarityIndex: similarityIndex,
                    temporaryResources: temporaryResources,
                    shouldAddSources: (
                        index == lastIndex
                    ),
                    useVisionContent: hasVision,
                    useWebSearch: useWebSearch,
                    useCanvas: useCanvas,
                    canvasSelection: canvasSelection
                )
            }
        // Respond to prompt
        if self.status.isForegroundTask && self.status != .deepResearch {
            if preQueryStatus == .cold {
                self.status = .coldProcessing
            } else {
                self.status = .processing
            }
        }
        // Send different response based on mode
        var response: LlamaServer.CompleteResponse? = nil
        switch mode {
            case .`default`:
                if modelType == .worker {
                    do {
                        response = try await self.workerModelServer.getChatCompletion(
                            mode: mode,
                            canReachRemoteServer: canReachRemoteServer,
                            messages: messagesWithSources,
                            progressHandler: { partialResponse in
                                DispatchQueue.main.async {
                                    // Update response
                                    self.handleCompletionProgress(
                                        showPreview: showPreview,
                                        partialResponse: partialResponse,
                                        handleResponseUpdate: handleResponseUpdate
                                    )
                                }
                            }
                        )
                    } catch {
                        response = try await self.mainModelServer.getChatCompletion(
                            mode: mode,
                            canReachRemoteServer: canReachRemoteServer,
                            messages: messagesWithSources,
                            progressHandler: { partialResponse in
                                DispatchQueue.main.async {
                                    // Update response
                                    self.handleCompletionProgress(
                                        showPreview: showPreview,
                                        partialResponse: partialResponse,
                                        handleResponseUpdate: handleResponseUpdate
                                    )
                                }
                            }
                        )
                    }
                } else {
                    response = try await self.mainModelServer.getChatCompletion(
                        mode: mode,
                        canReachRemoteServer: canReachRemoteServer,
                        messages: messagesWithSources,
                        progressHandler: { partialResponse in
                            DispatchQueue.main.async {
                                // Update response
                                self.handleCompletionProgress(
                                    showPreview: showPreview,
                                    partialResponse: partialResponse,
                                    handleResponseUpdate: handleResponseUpdate
                                )
                            }
                        }
                    )
                }
            case .chat, .agent:
                response = try await self.getChatResponse(
                    mode: mode,
                    modelType: modelType,
                    canReachRemoteServer: canReachRemoteServer,
                    messagesWithSources: messagesWithSources,
                    useWebSearch: useWebSearch,
                    useFunctions: useFunctions,
                    functions: functions,
                    similarityIndex: similarityIndex,
                    showPreview: showPreview,
                    handleResponseUpdate: handleResponseUpdate
                )
            case .deepResearch:
                // Indicate started Deep Research
                self.indicateStartedDeepResearch()
                // Init and run deep research workflow
                self.agent = DeepResearchAgent(
                    messages: messages,
                    similarityIndex: similarityIndex
                )
                response = try await self.agent?.run()
                self.agent = nil
                self.pendingMessage = nil
                self.status = .ready
        }
        // Handle response finish
        handleResponseFinish(
            response!.text,
            self.pendingMessage?.text ?? "",
            response!.usage?.total_tokens
        )
        // Update display
        if showPreview && self.agent == nil {
            self.pendingMessage = nil
            self.status = .ready
        }
        Self.logger.notice("Finished responding to prompt")
        return response!
    }
    
    /// A function to update the inference status
    private func updateStatus(
        _ status: Status
    ) {
        if self.status != status && self.status != .deepResearch {
            self.status = status
        }
    }
    
    /// Function to get response for chat
    private func getChatResponse(
        mode: Model.Mode,
        modelType: ModelType,
        canReachRemoteServer: Bool,
        messagesWithSources: [Message.MessageSubset],
        useWebSearch: Bool,
        useFunctions: Bool,
        functions: [AnyFunctionBox]? = nil,
        similarityIndex: SimilarityIndex? = nil,
        showPreview: Bool,
        handleResponseUpdate: @escaping (String, String) -> Void
    ) async throws -> LlamaServer.CompleteResponse {
        // Define increment for update
        let increment: Int = 8
        // Handle initial response
        let initialResponse = try await getInitialResponse(
            mode: mode,
            canReachRemoteServer: canReachRemoteServer,
            messages: messagesWithSources,
            useWebSearch: useWebSearch,
            useFunctions: useFunctions,
            functions: functions,
            showPreview: showPreview,
            handleResponseUpdate: handleResponseUpdate,
            increment: increment
        )
        // Return if functions are disabled
        if !Settings.useFunctions || !useFunctions {
            return initialResponse
        }
        // Return if no function call
        guard let functionCalls = initialResponse.functionCalls,
              !functionCalls.isEmpty else {
            return initialResponse
        }
        // Run agent in a loop
        return try await self.handleFunctionCall(
            canReachRemoteServer: canReachRemoteServer,
            initialResponse: initialResponse,
            messages: messagesWithSources,
            useWebSearch: useWebSearch,
            functions: functions,
            similarityIndex: similarityIndex,
            showPreview: showPreview,
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
        useFunctions: Bool,
        functions: [AnyFunctionBox]? = nil,
        showPreview: Bool,
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
            useFunctions: useFunctions,
            functions: functions,
            updateStatusHandler: { status in
                await self.updateStatus(status)
            },
            progressHandler:  { partialResponse in
                DispatchQueue.main.async {
                    updateResponse += partialResponse
                    let shouldUpdate = updateResponse.count >= increment ||
                    (self.pendingMessage?.text.count ?? 0 < increment)
                    if shouldUpdate {
                        self.handleCompletionProgress(
                            showPreview: showPreview,
                            partialResponse: updateResponse,
                            handleResponseUpdate: handleResponseUpdate
                        )
                        updateResponse = ""
                    }
                }
            }
        )
    }
    
    /// Function to run code if model calls a function
    private func handleFunctionCall(
        canReachRemoteServer: Bool,
        initialResponse: LlamaServer.CompleteResponse,
        messages: [Message.MessageSubset],
        useWebSearch: Bool,
        functions: [AnyFunctionBox]? = nil,
        similarityIndex: SimilarityIndex?,
        showPreview: Bool,
        handleResponseUpdate: @escaping (
            String, // Full message
            String // Delta
        ) -> Void = { _, _ in },
        increment: Int
    ) async throws -> LlamaServer.CompleteResponse {
        // Set status
        if self.status != .deepResearch {
            self.status = .usingFunctions
        }
        // Execute functions on a loop
        var maxIterations: Int = 30 // Max 30 tool calls
        var response: LlamaServer.CompleteResponse? = initialResponse
        var messages: [Message.MessageSubset] = messages
        // Capture results
        var results: [FunctionCallResult] = []
        while maxIterations > 0, let functionCalls = response?.functionCalls {
            // Execute each call
            var functionCallRecords = self.pendingMessage?.functionCallRecords ?? []
            for index in functionCalls.indices {
                var functionCall = functionCalls[index]
                // Log function call
                let callJsonSchema: String = functionCall.getJsonSchema()
                Self.logger.info("Executing function call: \(callJsonSchema, privacy: .public)")
                // Display call to user
                functionCallRecords = self.pendingMessage?.functionCallRecords ?? []
                var functionCallRecord: FunctionCallRecord = FunctionCallRecord(
                    name: functionCall.name
                )
                withAnimation(.linear) {
                    self.pendingMessage?.functionCallRecords = functionCallRecords + [functionCallRecord]
                    self.pendingMessage?.text = ""
                }
                // Call function
                do {
                    // Run
                    let result: String = try await functionCall.call() ?? "Function evaluated successfully"
                    // Mark as succeeded
                    functionCallRecord.markAsFinished(
                        status: .succeeded,
                        result: result
                    )
                    // Record tools called
                    let newResult: FunctionCallResult = FunctionCallResult(
                        call: callJsonSchema,
                        result: result,
                        type: .result
                    )
                    results.append(newResult)
                } catch {
                    // Get error description
                    let errorDescription: String = error.localizedDescription
                    // Mark as failed
                    functionCallRecord.markAsFinished(
                        status: .failed,
                        result: errorDescription
                    )
                    // Record tools called
                    let newResult: FunctionCallResult = FunctionCallResult(
                        call: callJsonSchema,
                        result: errorDescription,
                        type: .error
                    )
                    results.append(newResult)
                }
                withAnimation(.linear) {
                    functionCallRecords += [functionCallRecord]
                    self.pendingMessage?.functionCallRecords = functionCallRecords
                }
            }
            // Add assistant response message
            let responseMessage: Message = Message(
                text: response?.text ?? "",
                sender: .assistant
            )
            let responseMessageSubset: Message.MessageSubset = await Message.MessageSubset(
                usingRemoteModel: self.wasRemoteServerAccessible,
                message: responseMessage
            )
            messages.append(responseMessageSubset)
            // Check if further tool call is needed
            var hasMadeSufficientCalls: Bool = false
            let checkMode = Settings.FunctionCompletionCheckMode(
                Settings.checkFunctionsCompletion
            )
            if checkMode != .none,
               let modelType = checkMode.modelType {
                hasMadeSufficientCalls = await self.sufficientFunctionCalls(
                    modelType: modelType,
                    messages: messages,
                    canReachRemoteServer: canReachRemoteServer,
                    results: results
                )
            }
            // Formulate user message
            var messageStringComponents: [String] = results.map(
                \.description
            )
            // Add prompt
            let changePrompt: String = {
                if hasMadeSufficientCalls {
                    return """
Organize the information above into a response to the user's query.
"""
                } else {
                    return """
Call another tool to obtain more information or execute more actions. Try breaking down the user's query into steps, and find information about its constituent parts.
"""
                }
            }()
            messageStringComponents.append(changePrompt)
            let changeMessage = Message(
                text: messageStringComponents.joined(separator: "\n\n"),
                sender: .user
            )
            let changeMessageSubset = await Message.MessageSubset(
                usingRemoteModel: self.wasRemoteServerAccessible,
                message: changeMessage
            )
            messages.append(changeMessageSubset)
            // Declare variable for incremental update
            var updateResponse: String = ""
            self.pendingMessage?.text = updateResponse
            // Get response
            response = try await self.mainModelServer.getChatCompletion(
                mode: .chat,
                canReachRemoteServer: canReachRemoteServer,
                messages: messages,
                useWebSearch: useWebSearch,
                useFunctions: true,
                functions: functions,
                updateStatusHandler: { status in
                    await self.updateStatus(status)
                },
                progressHandler: { partialResponse in
                    DispatchQueue.main.async {
                        updateResponse += partialResponse
                        let shouldUpdate = updateResponse.count >= increment ||
                        (
                            self.pendingMessage?.text.count ?? 0 < increment
                        )
                        if shouldUpdate {
                            self.handleCompletionProgress(
                                showPreview: showPreview,
                                partialResponse: updateResponse,
                                handleResponseUpdate: handleResponseUpdate
                            )
                            updateResponse = ""
                        }
                    }
                }
            )
            response?.functionCallRecords = functionCallRecords
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
                mode: .default,
                canReachRemoteServer: canReachRemoteServer,
                messages: messages,
                progressHandler: { partialResponse in
                    DispatchQueue.main.async {
                        updateResponse += partialResponse
                        let shouldUpdate = updateResponse.count >= increment ||
                        (
                            self.pendingMessage?.text.count ?? 0 < increment
                        )
                        if shouldUpdate {
                            self.handleCompletionProgress(
                                showPreview: showPreview,
                                partialResponse: updateResponse,
                                handleResponseUpdate: handleResponseUpdate
                            )
                            updateResponse = ""
                        }
                    }
                }
            )
            if let functionCallRecords = self.pendingMessage?.functionCallRecords {
                response.functionCallRecords = functionCallRecords
            }
            return response
        }
        // An enum of reasons for finishing
        enum FinishReason {
            case noFunctionCall, maxIterationsReached
        }
    }
    
    /// Function to check if enough calls were made
    private func sufficientFunctionCalls(
        modelType: ModelType,
        messages: [Message.MessageSubset],
        canReachRemoteServer: Bool,
        results: [FunctionCallResult]
    ) async -> Bool {
        // Formulate prompt
        let resultPrompts: [String] = results.map { result in
            return result.description
        }
        let checkPrompt: String = """
\(resultPrompts.joined(separator: "\n\n"))

Have the tool calls above obtained enough information to solve the user's query?
Have the maximum number of tools been called to best fulfill the user's request?
Have all tool calls in your initial plan been executed successfully?

Respond with YES if ALL 3 criteria above have been met. Respond with YES or NO only.
"""
        let message: Message = Message(
            text: checkPrompt,
            sender: .user
        )
        let messageSubset: Message.MessageSubset = await Message.MessageSubset(
            usingRemoteModel: self.wasRemoteServerAccessible,
            message: message
        )
        // Add to messages
        var messages: [Message.MessageSubset] = messages
        messages.append(messageSubset)
        // Check with model for a maximum of 3 tries
        for _ in 0..<3 {
            do {
                // Get response
                let response = try await {
                    switch modelType {
                        case .regular:
                            try await self.mainModelServer.getChatCompletion(
                                mode: .`default`,
                                canReachRemoteServer: canReachRemoteServer,
                                messages: messages,
                                useWebSearch: false,
                                useFunctions: true
                            )
                        default:
                            try await self.workerModelServer.getChatCompletion(
                                mode: .`default`,
                                canReachRemoteServer: canReachRemoteServer,
                                messages: messages,
                                useWebSearch: false,
                                useFunctions: true
                            )
                    }
                }()
                let responseText: String = response.text.reasoningRemoved
                // Validate response
                let possibleResponses: [String] = ["YES", "NO"]
                if possibleResponses.contains(responseText) {
                    return responseText == "YES"
                }
            } catch {
                // Try again
                continue
            }
        }
        // If fell through, return false
        return false
    }
    
    /// Function to handle response update
    func handleCompletionProgress(
        showPreview: Bool = true,
        partialResponse: String,
        handleResponseUpdate: @escaping (
            String, // Full message
            String // Delta
        ) -> Void
    ) {
        // Assign if nil
        if self.pendingMessage == nil && showPreview {
            self.pendingMessage = Message(text: "", sender: .assistant)
        }
        let fullMessage: String = (self.pendingMessage?.text ?? "") + partialResponse
        handleResponseUpdate(
            fullMessage,
            partialResponse
        )
        if showPreview {
            self.pendingMessage?.text = fullMessage
        }
    }
    
    /// Function to check if the remote server is reachable
    /// - Returns: A `Bool` indicating if the server can be reached
    public func remoteServerIsReachable(
        endpoint: String = InferenceSettings.endpoint
    ) async -> Bool {
        // Return false if server is unused
        if !InferenceSettings.useServer { return false }
        // Try to use cached result
        let lastPathChangeDate: Date = NetworkMonitor.shared.lastPathChange
        if self.lastRemoteServerCheck >= lastPathChangeDate {
            Self.logger.info("Using cached remote server reachability result")
            return self.wasRemoteServerAccessible
        }
        // Get last path change time
        // If using server, check connection on multiple endpoints
        let testEndpoints: [String] = [
            "/models",
            "/chat/completions"
        ]
        for testEndpoint in testEndpoints {
            let endpoint: String = endpoint.replacingSuffix(
                testEndpoint,
                with: ""
            ) + testEndpoint
            guard let endpointUrl: URL = URL(
                string: endpoint
            ) else {
                continue
            }
            if await endpointUrl.isAPIEndpointReachable(
                timeout: 3
            ) {
                // Cache result, then return
                self.wasRemoteServerAccessible = true
                self.lastRemoteServerCheck = Date.now
                Self.logger.info("Reached remote server at '\(endpoint, privacy: .public)'")
                return true
            }
        }
        // If fell through, cache and return false
        Self.logger.warning("Could not reach remote server at '\(endpoint, privacy: .public)'")
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
        self.agent = nil
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
        /// The system is using a function
        case usingFunctions
        /// The system is doing deep research
        case deepResearch
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
                case .backgroundTask, .generatingTitle, .usingFunctions:
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
        /// Indicates the LLM is used as an agent
        case agent
        /// Indicates the LLM is used as an Deep Research agent
        case deepResearch
        /// Indicates the LLM is used for simple chat completion
        case `default`
        
        /// A `Bool` indiciating whether the mode is an agent
        var isAgent: Bool {
            switch self {
                case .agent, .deepResearch:
                    return true
                default:
                    return false
            }
        }
        
    }
    
}
