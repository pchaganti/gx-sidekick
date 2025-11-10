//
//  Model+Status.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import SwiftUI

extension Model {
    
    // MARK: - Pending Message Presentation
    
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
    
    public enum DisplayedContentType: CaseIterable {
        case indicator, text, preview
    }
    
    // MARK: - Status Management
    
    public func setStatus(_ newStatus: Status) {
        self.status = newStatus
    }
    
    var isProcessing: Bool {
        return status == .processing || status == .coldProcessing
    }
    
    func setSentConversationId(_ id: UUID) {
        // Reset pending message
        self.pendingMessage = nil
        self.sentConversationId = id
    }
    
    func indicateStartedNamingConversation() {
        // Reset pending message
        self.pendingMessage = nil
        self.status = .generatingTitle
    }
    
    func indicateStartedBackgroundTask() {
        // Reset pending message
        self.pendingMessage = nil
        self.status = .backgroundTask
    }
    
    func indicateStartedQuerying() {
        // Reset pending message
        self.pendingMessage = nil
        self.status = .querying
    }
    
    func indicateStartedDeepResearch() {
        // Reset pending message
        self.pendingMessage = nil
        self.status = .deepResearch
    }
    
}

// MARK: - Status Enum

extension Model {
    
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
    
}


