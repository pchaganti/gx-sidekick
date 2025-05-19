//
//  PromptInputField.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import OSLog
import SimilaritySearchKit
import SwiftUI
import AppKit

struct PromptInputField: View {
    
    /// A `Logger` object for the `PromptInputField` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: PromptInputField.self)
    )
    
    @AppStorage("useCommandReturn") private var useCommandReturn: Bool = Settings.useCommandReturn
    var sendShortcutDescription: Text {
        return Text(
            Settings.SendShortcut(self.useCommandReturn).rawValue
        )
        .italic()
    }
    
    @EnvironmentObject private var model: Model
    @EnvironmentObject private var conversationManager: ConversationManager
    @EnvironmentObject private var expertManager: ExpertManager
    @EnvironmentObject private var conversationState: ConversationState
    @EnvironmentObject private var promptController: PromptController
    @EnvironmentObject private var canvasController: CanvasController
    
    @FocusState var isFocused: Bool
    
    // NSEvent monitor token
    @State private var keyEventMonitor: Any?
    
    var selectedConversation: Conversation? {
        guard let selectedConversationId = conversationState.selectedConversationId else {
            return nil
        }
        return self.conversationManager.getConversation(
            id: selectedConversationId
        )
    }
    
    var selectedExpert: Expert? {
        guard let selectedExpertId = conversationState.selectedExpertId else {
            return nil
        }
        return expertManager.getExpert(id: selectedExpertId)
    }
    
    var messages: [Message] {
        return selectedConversation?.messages ?? []
    }
    
    var showQuickPrompts: Bool {
        return promptController.prompt.isEmpty && messages.isEmpty
    }
    
    var addFilesTip: AddFilesTip = .init()
    
    var buttonFillColor: Color {
        return self.promptController.isRecording ? Color.red : Color.accentColor
    }
    
    var body: some View {
        textField
            .onExitCommand {
                self.isFocused = false
            }
            .onChange(
                of: self.isFocused
            ) {
                // Show add files and dictation tips if needed
                if self.isFocused {
                    AddFilesTip.readyForAddingFiles = true
                }
            }
            .onChange(
                of: conversationState.selectedConversationId
            ) {
                self.isFocused = true
                self.promptController.didManuallyToggleReasoning = false
            }
            .onChange(
                of: conversationState.selectedExpertId
            ) {
                // If web search can be used
                if RetrievalSettings.canUseWebSearch,
                   let useWebSearch = self.selectedExpert?.useWebSearch {
                    // Sync web search settings
                    withAnimation(.linear) {
                        self.promptController.useWebSearch = useWebSearch
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notifications.changedInferenceConfig.name
                )
            ) { output in
                withAnimation(.linear) {
                    // Handle model change
                    self.handleModelChange()
                }
            }
            .onAppear {
                self.isFocused = true
                self.setupKeyEventMonitor()
            }
            .onDisappear {
                self.removeKeyEventMonitor()
            }
            .popoverTip(addFilesTip)
    }
    
    var textField: some View {
        ChatPromptEditor(
            isFocused: self._isFocused,
            isRecording: self.$promptController.isRecording,
            useAttachments: true,
            bottomOptions: true,
            cornerRadius: 22
        )
        .focused(self.$isFocused)
        .submitLabel(.send)
        .overlay(alignment: .leading) {
            AttachmentSelectionButton { url in
                await self.promptController.addFile(url)
            }
        }
        .overlay(alignment: .trailing) {
            DictationButton()
        }
        .overlay(alignment: .bottomLeading) {
            HStack {
                UseReasoningButton(
                    activatedFillColor: self.buttonFillColor,
                    useReasoning: self.$promptController.useReasoning
                )
                SearchMenuToggleButton(
                    activatedFillColor: self.buttonFillColor,
                    useWebSearch: self.$promptController.useWebSearch,
                    selectedSearchState: self.$promptController.selectedSearchState
                )
                UseFunctionsButton(
                    activatedFillColor: self.buttonFillColor,
                    useFunctions: self.$promptController.useFunctions
                )
            }
            .padding(.leading, 32)
            .padding(.bottom, 10)
            .frame(height: 25)
        }
        .padding([.vertical, .leading], 10)
    }
    
    /// Set up NSEvent keyDown monitor
    private func setupKeyEventMonitor() {
        // Remove previous monitor if any
        self.removeKeyEventMonitor()
        // Only monitor when focused
        if self.keyEventMonitor == nil {
            self.keyEventMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.keyDown]
            ) { event in
                // Only process if this view and window is focused
                if self.isFocused, event.window?.isMainWindow == true && event.window?.title.isEmpty == true {
                    if self.handleKeyDownEvent(event) {
                        return nil // handled, suppress
                    }
                }
                return event
            }
        }
    }
    
    /// Remove NSEvent monitor if exists (macOS only)
    private func removeKeyEventMonitor() {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
    }
    
    /// Handle NSEvent keyDown events (macOS only)
    @discardableResult
    private func handleKeyDownEvent(_ event: NSEvent) -> Bool {
        // Only interested in Return/Enter
        let isReturnKeyDown = (event.keyCode == 36) || (event.keyCode == 76) // 36 = Return, 76 = Numpad Enter
        if isReturnKeyDown {
            let isCommandKeyDown = event.modifierFlags.contains(.command)
            let isShiftKeyDown = event.modifierFlags.contains(.shift)
            let isOptionKeyDown = event.modifierFlags.contains(.option)
            let noModifiers = event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty
            
            Self.logger.info("Received key press with key \"\(event.characters ?? "nil", privacy: .public)\" and modifiers \"\(event.modifierFlags.rawValue, privacy: .public)\"")
            
            if isCommandKeyDown && self.useCommandReturn {
                // Send if command key is down and required
                self.onSubmit()
                return true
            } else if !self.useCommandReturn && noModifiers {
                // Else, if command key is not required, send
                self.onSubmit()
                return true
            } else if isShiftKeyDown || isOptionKeyDown || (self.useCommandReturn && noModifiers) {
                // Insert newline at cursor
                let index: String.Index = self.promptController.prompt.index(
                    atDistance: self.promptController.insertionPoint
                )
                DispatchQueue.main.async {
                    withAnimation {
                        self.promptController.prompt.insert(
                            "\n",
                            at: index
                        )
                        self.promptController.insertionPoint += 1
                    }
                }
                return true
            }
        }
        return false
    }
    
    /// Function to run when the `return` key is hit
    private func onSubmit() {
        // If not blank, submit
        if promptController.prompt.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            // End recording
            self.promptController.stopRecording()
            // Send message
            self.submit()
        }
    }
    
    /// Function to send to bot
    private func submit() {
        // Get previous content
        guard var conversation = selectedConversation else { return }
        // Check if last message was successful
        if let prevMessage: Message = conversation.messages.last {
            // If unsuccessful
            let wasAssistant: Bool = prevMessage.getSender() == .assistant
            if prevMessage.text.isEmpty && prevMessage.imageUrl == nil && wasAssistant {
                // Tell user to retry
                Dialogs.showAlert(
                    title: String(localized: "Retry"),
                    message: String(localized: "Please retry your previous message.")
                )
                return
            }
        }
        // Make sound
        if Settings.playSoundEffects {
            SoundEffects.send.play()
        }
        // Get prompt expected result type
        var resultType: PromptAnalyzer.ResultType = .text
        if !self.promptController.isUsingDeepResearch {
            resultType = PromptAnalyzer.getExpectedResultType(
                promptController.prompt
            )
        }
        // Check web search
        if !self.checkWebSearch() {
            return
        }
        // Make request message
        let newUserMessage: Message = Message(
            text: promptController.prompt,
            sender: .user
        )
        DispatchQueue.main.async {
            let _ = conversation.addMessage(newUserMessage)
            conversationManager.update(conversation)
        }
        // Store sent properties
        DispatchQueue.main.async {
            self.promptController.sentConversation = conversation
            self.promptController.sentExpertId = self.conversationState.selectedExpertId
        }
        // Capture temp resources
        let tempResources: [TemporaryResource] = self.promptController.tempResources
        // If result type is text, send message
        switch resultType {
            case .text:
                self.startTextGeneration(
                    prompt: promptController.prompt,
                    useReasoning: promptController.useReasoning,
                    tempResources: tempResources
                )
            case .image:
                // If image generation is available, start generating image
                if PromptAnalyzer.ResultType.image.isAvailable {
                    self.startImageGeneration()
                } else {
                    // Else, fall back to text
                    self.startTextGeneration(
                        prompt: promptController.prompt,
                        useReasoning: promptController.useReasoning,
                        tempResources: tempResources
                    )
                }
        }
        // Clear prompt
        self.clearInputs()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.clearInputs()
        }
    }
    
    private func startTextGeneration(
        prompt: String,
        useReasoning: Bool,
        tempResources: [TemporaryResource]
    ) {
        // Get response
        Task {
            await self.generateChatResponse(
                prompt: prompt,
                useReasoning: useReasoning,
                tempResources: tempResources
            )
        }
    }
    
    private func startImageGeneration() {
        if #available(macOS 15.2, *) {
            // Start generation
            self.promptController.imageConcept = self.promptController.prompt
            self.promptController.isGeneratingImage = true
            // Reset sent properties
            self.promptController.sentConversation = nil
        }
    }
    
    private func clearInputs() {
        DispatchQueue.main.async {
            self.promptController.didManuallyToggleReasoning = false
            self.promptController.prompt.removeAll()
        }
    }
    
    private func generateChatResponse(
        prompt: String,
        useReasoning: Bool,
        tempResources: [TemporaryResource]
    ) async {
        // If processing, use recursion to update
        if (model.status == .processing || model.status == .coldProcessing) {
            Task {
                await model.interrupt()
                Task.detached(priority: .userInitiated) {
                    try? await Task.sleep(for: .seconds(1))
                    await generateChatResponse(
                        prompt: prompt,
                        useReasoning: useReasoning,
                        tempResources: tempResources
                    )
                }
            }
            return
        }
        // Get and save conversation
        guard var conversation = self.promptController.sentConversation else { return }
        self.model.setSentConversationId(conversation.id)
        // Generate title & update again
        let isFirstMessage: Bool = conversation.messages.count <= 1
        if Settings.generateConversationTitles && isFirstMessage {
            self.model.indicateStartedNamingConversation()
            if let title = try? await self.generateConversationTitle(
                prompt: prompt
            ), !title.isEmpty {
                conversation.title = title
            }
            withAnimation(.linear) {
                self.conversationManager.update(conversation)
            }
        }
        // Get response
        var response: LlamaServer.CompleteResponse
        var didUseSources: Bool = false
        do {
            self.model.indicateStartedQuerying()
            var index: SimilarityIndex? = nil
            // If there are resources
            if !((selectedExpert?.resources.resources.isEmpty) ?? true) {
                // Load
                index = await selectedExpert?.resources.loadIndex()
            }
            let useWebSearch: Bool = self.promptController.useWebSearch
            // Set if sources were used
            let hasIndexItems: Bool = !((
                index?.indexItems.isEmpty
            ) ?? true)
            didUseSources = useWebSearch || hasIndexItems || !tempResources.isEmpty
            // Get mode
            let mode: Model.Mode = self.promptController.isUsingDeepResearch ? .deepResearch : .chat
            // Get response
            response = try await model.listenThinkRespond(
                messages: conversation.messages,
                modelType: .regular,
                mode: mode,
                similarityIndex: index,
                useReasoning: useReasoning,
                useWebSearch: useWebSearch,
                useFunctions: self.promptController.useFunctions,
                useCanvas: self.conversationState.useCanvas,
                canvasSelection: self.canvasController.selection,
                temporaryResources: tempResources,
                showPreview: true
            )
        } catch let error as LlamaServerError {
            await model.interrupt()
            self.handleResponseError(error)
            return
        } catch {
            print("Agent listen threw unexpected error", error as Any)
            return
        }
        // Update UI
        await MainActor.run {
            // Output final output to debug console
            // Make response message
            var responseMessage: Message = Message(
                text: response.text,
                sender: .assistant,
                model: response.modelName,
                functionCallRecords: response.functionCallRecords,
                expertId: promptController.sentExpertId
            )
            responseMessage.update(
                response: response,
                includeReferences: didUseSources
            )
            responseMessage.end()
            // Update conversation
            let _ = conversation.addMessage(
                responseMessage
            )
            conversation.tokenCount = response.usage?.total_tokens
            self.conversationManager.update(conversation)
            // Make sound
            if Settings.playSoundEffects {
                SoundEffects.ping.play()
            }
            // Reset sentConversation
            self.promptController.sentConversation = nil
        }
        // Memorize content if needed
        if RetrievalSettings.useMemory,
           let assistantMessage: Message = conversation.messages.last,
           let userMessage: Message = conversation.messages.dropLast(1).last,
           assistantMessage.getSender() == .assistant,
           userMessage.getSender() == .user {
            await Memories.shared.rememberIfNeeded(
                messageId: assistantMessage.id,
                text: userMessage.text
            )
        }
    }
    
    /// Function to generate a title for the conversation
    private func generateConversationTitle(
        prompt: String
    ) async throws -> String? {
        // Formulate messages
        let generateTitleMessage: Message = Message(
            text: """
A user is chatting with an assistant and they have sent the message below. Generate an extremely short label for the chat session. Actively remove details from the user's message to make the label sho[...]

"\(prompt)"
""",
            sender: .user
        )
        let messages: [Message] = [
            generateTitleMessage
        ]
        // Generate
        let title: String = try await model.listenThinkRespond(
            messages: messages,
            modelType: .worker,
            mode: .default,
            useReasoning: false
        ).text
        // Reset pending message text
        self.model.pendingMessage = nil
        // Return
        return title
            .reasoningRemoved
            .trimmingWhitespaceAndNewlines()
            .capitalizeEachWord
            .dropPrefixIfPresent("\"")
            .dropSuffixIfPresent("\"")
    }
    
    @MainActor
    private func handleResponseError(_ error: LlamaServerError) {
        // Display error message
        let errorDescription: String = error.errorDescription ?? "Unknown Error"
        let recoverySuggestion: String = error.recoverySuggestion
        Dialogs.showAlert(
            title: errorDescription,
            message: recoverySuggestion
        )
        // Restore prompt
        if let prompt: String = self.promptController.sentConversation?.messages.last?.text {
            self.promptController.prompt = prompt
        }
        // Remove messages
        if let messages: [Message] = self.promptController.sentConversation?.messages.dropLast(1),
           var conversation = self.promptController.sentConversation {
            // Drop message and update
            conversation.messages = messages
            self.conversationManager.update(conversation)
        }
        // Reset model status
        self.model.status = .ready
        self.model.sentConversationId = nil
    }
    
    /// Function to check if web search can be used
    private func checkWebSearch() -> Bool {
        // If web search is on, but cannot be used
        let success: Bool = !(!RetrievalSettings.canUseWebSearch && self.promptController.useWebSearch)
        if !success {
            // Show dialog
            Dialogs.showAlert(
                title: String(localized: "Search not configured"),
                message: String(localized: "Search is not configured. Please configure it in \"Settings\" -> \"Retrieval\".")
            )
            self.promptController.useWebSearch = false
        }
        return success
    }
    
    private func handleModelChange() {
        // Get selected model
        if let model = Model.shared.selectedModel {
            let isReasoningModel: Bool = model.isReasoningModel
            // Update reasoning
            self.promptController.useReasoning = isReasoningModel
            // Update search
            if !isReasoningModel && self.promptController.isUsingDeepResearch {
                self.promptController.useWebSearch = false
                self.promptController.selectedSearchState = .search
            }
        } else {
            // Default to false
            self.promptController.useReasoning = false
            if self.promptController.isUsingDeepResearch {
                self.promptController.useWebSearch = false
                self.promptController.selectedSearchState = .search
            }
        }
    }
    
}
