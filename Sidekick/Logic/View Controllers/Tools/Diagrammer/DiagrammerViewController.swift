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
	
	/// The full prompt used to generate D2 diagram code, of type `String`
	var fullPrompt: String {
		// Init prompt text
		let prompt: String = """
\(self.prompt)

Use D2 markup language to draw a highly detailed diagram, following the syntax in the provided cheatsheet. Respond with ONLY the D2 code.
"""
		// Get cheatsheet text
		guard let cheatsheetURL: URL = Bundle.main.url(
			forResource: "d2-cheatsheet",
			withExtension: "txt"
		) else {
			return prompt
		}
		let cheatsheetText: String = try! String(contentsOf: cheatsheetURL)
		// Return full prompt
		return """
\(prompt)

Cheatsheet:

\(cheatsheetText)
"""
	}
	
	/// The d2 child process to serve the preview
	var d2PreviewServerProcess: Process = Process()
	/// The d2 child process to render the image
	var d2RenderProcess: Process = Process()
	/// The port where the preview is hosted
	let port: Int = 2942
	
	/// The D2 code, of type `String`
	@Published public var d2Code: String = ""
	
	/// A preview of the diagram
	public var preview: some View {
		WebView(
			url: URL(
				string: "http://127.0.0.1:\(self.port)"
			)!
		)
	}
	
	/// The URL of the d2 code file, of type `URL`
	private var d2FileUrl: URL {
		let d2FileUrl: URL = Settings
			.cacheUrl
			.appendingPathComponent(
				"newDiagram.d2"
			)
		return d2FileUrl
	}
	
	/// Function to save the D2 code
	public func saveD2Code() {
		// Save D2 text to file
		do {
			try self.d2Code.write(
				to: self.d2FileUrl,
				atomically: true,
				encoding: .utf8
			)
		} catch {
			Self.logger.error("Error saving D2 code: \(error, privacy: .public)")
		}
	}
	
	/// Function to start the preview from the D2 code
	public func startPreview() {
		// Save the code
		self.saveD2Code()
		// Start the D2 child process
		self.d2PreviewServerProcess = Process()
		self.d2PreviewServerProcess.executableURL = Bundle.main.resourceURL?.appendingPathComponent("d2")
		let arguments = [
			"--watch",
			self.d2FileUrl.posixPath,
			"--port",
			"\(self.port)",
			"--browser",
			"0"
		]
		self.d2PreviewServerProcess.arguments = arguments
		self.d2PreviewServerProcess.standardInput = FileHandle.nullDevice
		// To debug with server's output, comment these 2 lines to inherit stdout.
		self.d2PreviewServerProcess.standardOutput =  FileHandle.nullDevice
		self.d2PreviewServerProcess.standardError =  FileHandle.nullDevice
		// Run the process
		do {
			try self.d2PreviewServerProcess.run()
			Self.logger.notice("Started diagrammer preview server")
		} catch {
			// Print error
			print("Error generating diagram: \(error)")
			// Return to first step
			Task.detached { @MainActor in
				Dialogs.showAlert(
					title: String(localized: "Error"),
					message: String(localized: "An error occurred while generating the diagram.")
				)
				self.stopPreview()
			}
		}
	}
	
	/// Function to stop the preview
	public func stopPreview() {
		// Exit if not running
		if self.d2PreviewServerProcess.executableURL == nil { return }
		// Else, terminate and reinit
		Self.logger.notice("Stopping diagrammer preview server")
		self.d2PreviewServerProcess.terminate()
		self.d2PreviewServerProcess = Process()
	}
	
	/// Function to stop the render process
	public func stopRender() {
		// Exit if not running
		if self.d2RenderProcess.executableURL == nil { return }
		self.d2RenderProcess.terminate()
		// Else, terminate and reinit
		self.d2RenderProcess = Process()
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
			// Generate image
			self.d2RenderProcess = Process()
			self.d2RenderProcess.executableURL = Bundle.main.resourceURL?
				.appendingPathComponent("d2")
			let saveUrl: URL = url.appendingPathComponent(
				"diagram \(Date.now.dateString).svg"
			)
			self.d2RenderProcess.arguments = [
				self.d2FileUrl.posixPath,
				saveUrl.posixPath
			]
			self.d2RenderProcess.standardInput = FileHandle.nullDevice
			// To debug with server's output, comment these 2 lines to inherit stdout.
			self.d2RenderProcess.standardOutput =  FileHandle.nullDevice
			self.d2RenderProcess.standardError =  FileHandle.nullDevice
			do {
				try self.d2RenderProcess.run()
				Self.logger.notice("Started diagrammer render process")
				// Return success
				return true
			} catch {
				Self.logger.error("Failed to start diagrammer render process: \(error, privacy: .public)")
				// Return fail
				return false
			}
		}
		// Return fail
		return false
	}
	
	/// Function to submit the prompt
	public func submitPrompt() {
		// Reset d2Code
		self.d2Code = ""
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
		// Generate the D2 code
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
						let d2Code: String = fullMessage.reasoningRemoved.replacingOccurrences(
							of: "```D2",
							with: ""
						).replacingOccurrences(
							of: "```d2",
							with: ""
						).replacingOccurrences(
							of: "```",
							with: ""
						).replacingOccurrences(
							of: "_",
							with: " "
						).trimmingWhitespaceAndNewlines()
						// Set the D2 code
						self.d2Code = d2Code
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
	
	/// The steps to generate the D2 diagram
	public enum DiagrammerStep: CaseIterable {
		
		case prompt
		case generating
		case editAndPreview
		
	}
	
}
