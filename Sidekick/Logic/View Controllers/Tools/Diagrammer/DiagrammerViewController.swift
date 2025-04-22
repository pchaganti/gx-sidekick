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
		// Return full prompt
        return prompt
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
	
	/// Function to start the preview from the mermaid code
	public func startPreview() {
		// Save the code
        self.saveMermaidCode()
		// Start the mermaid child process
		self.mermaidPreviewServerProcess = Process()
		self.mermaidPreviewServerProcess.executableURL = Bundle.main.resourceURL?.appendingPathComponent("mermaid-cli")
		let arguments = [
			"-watch",
			self.mermaidFileUrl.posixPath
		]
		self.mermaidPreviewServerProcess.arguments = arguments
		self.mermaidPreviewServerProcess.standardInput = FileHandle.nullDevice
        let pipe: Pipe = Pipe()
		self.mermaidPreviewServerProcess.standardOutput = pipe
		self.mermaidPreviewServerProcess.standardError =  FileHandle.nullDevice
		// Run the process
		do {
            // Setup monitor
            let id: UUID = self.previewId
            self.fileMonitor = try? FileMonitor(
                url: Self.previewFileUrl
            ) {
                // Render
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1
                ) {
                    self.previewId = UUID()
                    Self.logger.notice("Updated diagrammer preview")
                }
            }
            try self.mermaidPreviewServerProcess.run()
			Self.logger.notice("Started diagrammer preview server")
            // If file not updated, trigger error
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.previewId == id {
                    self.handleRenderError()
                }
            }
		} catch {
			// Print error
            Self.logger.error("Error generating diagram: \(error)")
            self.handleRenderError()
		}
	}
    
    public func handleRenderError() {
        // Return to first step
        Task { @MainActor in
            Dialogs.showAlert(
                title: String(localized: "Error"),
                message: String(localized: "Could not render the diagram within reasonable time.")
            )
            self.stopPreview()
        }
    }
	
	/// Function to stop the preview
	public func stopPreview() {
		// Exit if not running
		if self.mermaidPreviewServerProcess.executableURL == nil { return }
		// Else, terminate and reinit
		Self.logger.notice("Stopping diagrammer preview server")
		self.mermaidPreviewServerProcess.terminate()
		self.mermaidPreviewServerProcess = Process()
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
		// Generate the mermaid code
		Task { @MainActor in
			do {
				let _ = try await Model.shared.listenThinkRespond(
					messages: [
						systemPromptMessage,
						commandMessage
                    ],
                    modelType: .regular,
					mode: .default, handleResponseFinish:  { fullMessage, pendingMessage, _ in
						// On finish
						// Remove markdown code tags and thinking process
						let mermaidCode: String = fullMessage.reasoningRemoved.replacingOccurrences(
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
						self.startPreview()
						// Move to next step
						self.currentStep.nextCase()
					})
			} catch {
				// If failed, show error
				Dialogs.showAlert(
					title: String(localized: "Error"),
					message: String(localized: "An error occurred while generating the diagram.")
				)
				// Restart the process
				self.stopPreview()
			}
		}
		// Reset prompt
		self.prompt = ""
	}
	
	/// The steps to generate the mermaid diagram
	public enum DiagrammerStep: CaseIterable {
		
		case prompt
		case generating
		case editAndPreview
		
	}
	
}
