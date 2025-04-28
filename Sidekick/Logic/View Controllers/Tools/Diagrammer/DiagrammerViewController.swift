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
	
	/// The mermaid child process to serve the preview
	var mermaidPreviewServerProcess: Process = Process()
	
	/// The mermaid code, of type `String`
	@Published public var mermaidCode: String = ""
    
    /// A file monitor to watch for changes in the preview
    private var fileMonitor: FileMonitor?
    /// The preview's ID
    @Published private var previewId: UUID = UUID()
    
	/// A preview of the diagram
	public var preview: some View {
		WebView(
            url: Self.previewFileUrl
		)
        .id(previewId)
	}
	
	/// The URL of the mermaid code file, of type `URL`
	private var mermaidFileUrl: URL {
		let mermaidDirUrl: URL = Settings
			.cacheUrl
            .appendingPathComponent("Diagrammer")
        if !mermaidDirUrl.fileExists {
            FileManager.createDirectory(
                at: mermaidDirUrl,
                withIntermediateDirectories: true
            )
        }
        return mermaidDirUrl.appendingPathComponent(
            "newDiagram.mmd"
        )
	}
    
    /// The URL of the previewed file, of type `URL`
    private static var previewFileUrl: URL {
        let mermaidDirUrl: URL = Settings
            .cacheUrl
            .appendingPathComponent("Diagrammer")
        if !mermaidDirUrl.fileExists {
            FileManager.createDirectory(
                at: mermaidDirUrl,
                withIntermediateDirectories: true
            )
        }
        return mermaidDirUrl.appendingPathComponent(
            "newDiagram.svg"
        )
    }
	
	/// Function to save the mermaid code
	public func saveMermaidCode() {
		// Save mermaid text to file
		do {
			try self.mermaidCode.write(
				to: self.mermaidFileUrl,
				atomically: true,
				encoding: .utf8
			)
		} catch {
			Self.logger.error("Error saving mermaid code: \(error, privacy: .public)")
		}
	}
	
    /// Function to render the preview from the mermaid code
    public func render(
        attemptsRemaining: Int = 3
    ) throws {
        // Save the code
        self.saveMermaidCode()
        // Start the mermaid child process
        self.mermaidPreviewServerProcess = Process()
        self.mermaidPreviewServerProcess.executableURL = Bundle.main.resourceURL?.appendingPathComponent("mermaid-cli")
        let arguments = [
            "-log",
            self.mermaidFileUrl.posixPath
        ]
        self.mermaidPreviewServerProcess.arguments = arguments
        self.mermaidPreviewServerProcess.standardInput = FileHandle.nullDevice
        // Capture stdout and stderr
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        self.mermaidPreviewServerProcess.standardOutput = outputPipe
        self.mermaidPreviewServerProcess.standardError = errorPipe
        var renderError: String?
        let renderErrorSemaphore = DispatchSemaphore(value: 0)
        do {
            // Setup monitor
            let id: UUID = self.previewId
            self.fileMonitor = try? FileMonitor(
                url: Self.previewFileUrl
            ) {
                // Render
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.5
                ) {
                    self.previewId = UUID()
                    self.fileMonitor = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    Self.logger.notice("Updated diagrammer preview")
                }
            }
            try self.mermaidPreviewServerProcess.run()
            Self.logger.notice("Started diagrammer preview server")
            // Read error output asynchronously
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty,
                    let output = String(data: data, encoding: .utf8),
                    !output.isEmpty {
                    // Detect error lines (simple check for "error:" or "Parse error")
                    if output.lowercased().contains("error:") || output.lowercased().contains("parse error") {
                        Self.logger.error("`mermaid-cli` error: \(output)")
                        renderError = output
                        // Signal that an error was detected
                        renderErrorSemaphore.signal()
                    }
                }
            }
            // Wait for possible error or file update for a short duration
            let timeout: DispatchTime = .now() + 1.5
            let result = renderErrorSemaphore.wait(timeout: timeout)
            if result == .success, let errorOutput = renderError {
                // Error detected
                self.fileMonitor = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                if attemptsRemaining > 0 {
                    throw RenderError.error(errorOutput)
                } else {
                    DispatchQueue.main.async {
                        self.displayRenderError(errorMessage: errorOutput)
                    }
                    return
                }
            } else {
                // If file not updated, trigger error if last attempt
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if self.previewId == id, attemptsRemaining == 0 {
                        errorPipe.fileHandleForReading.readabilityHandler = nil
                        self.fileMonitor = nil
                        self.displayRenderError()
                    }
                }
            }
        } catch {
            // Print error
            Self.logger.error("Error generating diagram: \(error)")
            errorPipe.fileHandleForReading.readabilityHandler = nil
            self.fileMonitor = nil
            if attemptsRemaining > 0 {
                throw error
            } else {
                self.displayRenderError(errorMessage: error.localizedDescription)
            }
        }
    }
    
    private enum RenderError: LocalizedError {
        case error(String)
        public var errorDescription: String? {
            switch self {
                case .error(let string):
                    return string
            }
        }
    }
    
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
                    at: Self.previewFileUrl,
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
	
	/// The steps to generate the mermaid diagram
	public enum DiagrammerStep: CaseIterable {
		
		case prompt
		case generating
		case editAndPreview
		
	}
	
}
