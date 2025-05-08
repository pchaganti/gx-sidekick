//
//  DiagrammerViewController.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import Foundation
import FSKit_macOS
import OSLog
import SwiftUI
import WebViewKit

public class DiagrammerViewController: ObservableObject {
	
	/// A `Logger` object for the `DiagrammerViewController` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: DiagrammerViewController.self)
	)
	
	/// The current step in the diagram generation process, of type `DiagrammerStep`
	@Published public var currentStep: DiagrammerStep = .prompt
	
	/// The prompt entered, of type `String`
	@Published public var prompt: String = ""
	
	/// The full prompt used to generate mermaid diagram code, of type `String`
	var fullPrompt: String {
		// Init prompt text
		let prompt: String = """
Use Mermaid markup language to draw a highly detailed diagram for the topic below. Respond with ONLY the Mermaid code.

\(self.prompt)
"""
        // Get cheatsheet text
        guard let cheatsheetURL: URL = Bundle.main.url(
            forResource: "mermaidCheatsheet",
            withExtension: "md"
        ) else {
            return prompt
        }
        let cheatsheetText: String = try! String(
            contentsOf: cheatsheetURL,
            encoding: .utf8
        )
		// Return full prompt
        return """
\(prompt)

Cheatsheet:

\(cheatsheetText)
"""
	}
	
	/// The mermaid code, of type `String`
	@Published public var mermaidCode: String = ""
    
    /// The preview's ID
    @Published private var previewId: UUID = UUID()
    
	/// A preview of the diagram
	public var preview: some View {
		WebView(
            url: MermaidRenderer.previewFileUrl
		)
        .id(previewId)
	}
    
    /// Function to render the diagram from the mermaid code
    public func render(
        attemptsRemaining: Int = 3
    ) throws {
        // Return if code is empty
        guard !self.mermaidCode.isEmpty else {
            return
        }
        // Init renderer
        let renderer: MermaidRenderer = MermaidRenderer()
        // Save mermaid code
        MermaidRenderer.saveMermaidCode(code: self.mermaidCode)
        // Render
        try renderer.render(
            attemptsRemaining: attemptsRemaining
        ) {
            // On render finish
            self.previewId = UUID()
            Self.logger.notice("Updated diagrammer preview")
        } onError: { error in
            // On render error
            self.displayRenderError(errorMessage: error)
        }
    }
	
	/// Function to save an image of the diagram
	@MainActor
	public func saveImage() -> Bool {
		// Let user select a directory
		if let url: URL = try? FileManager.selectFile(
			rootUrl: .downloadsDirectory,
			dialogTitle: String(localized: "Select a Folder"),
			canSelectFiles: false
        ).first {
            do {
                Self.logger.notice("Started diagrammer render")
                // Relocate file
                try FileManager.default.moveItem(
                    at: MermaidRenderer.previewFileUrl,
                    to: url.appendingPathComponent(
                        "newDiagram.svg"
                    )
                )
                // Return success
                return true
            } catch {
                Self.logger.error("Failed to render diagram: \(error, privacy: .public)")
                // Return fail
                return false
            }
        }
		// Return fail
		return false
	}
	
	/// Function to submit the prompt
	public func submitPrompt() {
		// Reset mermaidCode
		self.mermaidCode = ""
		// Set step to generating
		self.currentStep.nextCase()
		// Formulate message
		let systemPromptMessage: Message = Message(
			text: InferenceSettings.systemPrompt,
			sender: .system
		)
		let commandMessage: Message = Message(
			text: self.fullPrompt,
			sender: .user
		)
        var messages: [Message] = [systemPromptMessage, commandMessage]
        // Reset prompt
        self.prompt = ""
		// Generate the mermaid code
		Task { @MainActor in
            // Init attempts remaining
            var attemptsRemaining: Int = 3
            var responseText: String? = nil
            // Loop
            while attemptsRemaining >= 0 {
                do {
                    let response = try await Model.shared.listenThinkRespond(
                        messages: messages,
                        modelType: .regular,
                        mode: .`default`
                    )
                    // On finish
                    let fullResponse: String = response.text
                    responseText = fullResponse
                    // Remove markdown code tags and thinking process
                    let mermaidCode: String = fullResponse.reasoningRemoved.replacingOccurrences(
                        of: "```mermaid",
                        with: ""
                    ).replacingOccurrences(
                        of: "```",
                        with: ""
                    ).replacingOccurrences(
                        of: "_",
                        with: " "
                    ).trimmingWhitespaceAndNewlines()
                    // Set the mermaid code
                    self.mermaidCode = mermaidCode
                    try self.render(
                        attemptsRemaining: attemptsRemaining
                    )
                    // Move to next step
                    self.currentStep.nextCase()
                    // Exit
                    return
                } catch {
                    // Try to get response text
                    guard let responseText = responseText else {
                        self.displayRenderError()
                        return
                    }
                    let responseMessage: Message = Message(
                        text: responseText,
                        sender: .assistant
                    )
                    messages.append(responseMessage)
                    // Try again with error message
                    let errorText: String = """
The following error output was returned when rendering the diagram:

\(error.localizedDescription)

Fix the error. Respond with ONLY the corrected Mermaid code.
"""
                    let iterateMessage: Message = Message(
                        text: errorText,
                        sender: .user
                    )
                    messages.append(iterateMessage)
                    // Increment attempts
                    attemptsRemaining -= 1
                    // Log
                    Self.logger.warning("Diagram render failed. Iterating with the error \"\(error.localizedDescription)\"")
                }
            }
        }
	}
    
    /// Function to display render error
    public func displayRenderError(
        errorMessage: String? = nil
    ) {
        let message: String = errorMessage ?? String(localized: "Could not render the diagram within reasonable time.")
        // Return to first step
        Task { @MainActor in
            Dialogs.showAlert(
                title: String(localized: "Error"),
                message: message
            )
        }
    }
	
	/// The steps to generate the mermaid diagram
	public enum DiagrammerStep: CaseIterable {
		
		case prompt
		case generating
		case editAndPreview
		
	}
	
}
