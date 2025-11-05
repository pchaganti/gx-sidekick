//
//  MessageShareMenu.swift
//  Sidekick
//
//  Created by Bean John on 10/30/24.
//

import FSKit_macOS
import SwiftUI

struct MessageShareMenu: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var model: Model
    @EnvironmentObject private var conversationManager: ConversationManager
    @EnvironmentObject private var expertManager: ExpertManager
    @EnvironmentObject private var conversationState: ConversationState
    
    var toolbarTextColor: Color = .primary
    
    var messages: [Message] {
        return self.selectedConversation?.messages ?? []
    }
    
    var conversationName: String {
        return self.selectedConversation?.title ?? "conversation"
    }
    
    var selectedExpert: Expert? {
        guard let selectedExpertId = conversationState.selectedExpertId else {
            return nil
        }
        return expertManager.getExpert(id: selectedExpertId)
    }
    
    var selectedConversation: Conversation? {
        guard let selectedConversationId = conversationState.selectedConversationId else {
            return nil
        }
        return self.conversationManager.getConversation(
            id: selectedConversationId
        )
    }
    
    var isGenerating: Bool {
        let statusPass: Bool = self.model.status.isWorking
        let conversationPass: Bool = self.selectedConversation?.id == self.model.sentConversationId
        return statusPass && conversationPass
    }
    
    var body: some View {
        Menu {
            self.saveTextButton
            self.saveHTMLButton
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
                .foregroundStyle(toolbarTextColor)
        }
        .disabled(isGenerating || self.messages.isEmpty)
    }
    
    var saveTextButton: some View {
        Button {
            self.saveText()
        } label: {
            Label("Save as Text", systemImage: "square.and.arrow.up")
                .labelStyle(.titleOnly)
        }
    }
    
    var saveHTMLButton: some View {
        Button {
            self.saveHTML()
        } label: {
            Label("Save as HTML", systemImage: "square.and.arrow.up")
                .labelStyle(.titleOnly)
        }
    }
    
    /// Function to export messages as text
    private func saveText() {
        // Convert messages to text
        let text: String = self.messages.map({ message in
            return """
\(message.getSender().rawValue.capitalized):
\(message.text)
"""
        }).joined(separator: "\n\n")
        // Save text to file
        self.saveToFile(
            string: text,
            fileName: "\(self.conversationName).txt"
        )
    }
    
    /// Function to export messages as HTML
    private func saveHTML() {
        // Load the HTML template
        guard let templatePath = Bundle.main.path(
            forResource: "conversationExportTemplate",
            ofType: "html"
        ), var htmlTemplate = try? String(
            contentsOfFile: templatePath,
            encoding: .utf8
        ) else {
            // If failed to load the template, show error and exit
            self.showSaveErrorDialog()
            return
        }
        // Generate the message HTML
        let chatDataJS: String = self.generateChatDataJS(from: messages)
        htmlTemplate = htmlTemplate.replacingOccurrences(
            of: "// CHAT_DATA_PLACEHOLDER",
            with: chatDataJS
        )
        // Save the HTML to a file
        self.saveToFile(
            string: htmlTemplate,
            fileName: "\(self.conversationName).html"
        )
    }
    
    /// Function to produce JS code for message objects
    private func generateChatDataJS(from messages: [Message]) -> String {
        var js = "const chatData = [\n"
        for (index, message) in messages.enumerated() {
            let sender = message.getSender().rawValue
            let escapedContent = self.escapeJSString(message.responseText)
            let escapedReasoning = self.escapeJSString(message.reasoningText ?? "")
            js += """
        {
            id: \(index + 1),
            role: '\(sender)',
            content: `\(escapedContent)`,
            reasoning: `\(escapedReasoning)`,
            timestamp: ""
        },
        """
        }
        js += "];"
        return js
    }
    
    /// Function to apply escapes for special symbols in JS string
    private func escapeJSString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
    }
    
    /// Function to save text to file
    private func saveToFile(
        string: String,
        fileName: String
    ) {
        // Get save location
        if let url = try? FileManager.selectFile(
            dialogTitle: String(localized: "Select a Save Location"),
            canSelectFiles: false
        ).first {
            // Save text to file
            do {
                let fileUrl: URL = url.appendingPathComponent(fileName)
                try string.write(
                    to: fileUrl,
                    atomically: true,
                    encoding: .utf8
                )
            } catch {
                self.showSaveErrorDialog()
            }
        }
    }
    
    /// Function to show save error dialog
    private func showSaveErrorDialog() {
        Dialogs.showAlert(
            title: String(localized: "Error"),
            message: String(localized: "Failed to save messages.")
        )
    }
    
}
