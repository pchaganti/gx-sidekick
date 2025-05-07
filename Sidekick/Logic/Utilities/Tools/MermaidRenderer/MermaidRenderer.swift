//
//  MermaidRenderer.swift
//  Sidekick
//
//  Created by John Bean on 5/7/25.
//

import Foundation
import OSLog

public class MermaidRenderer {
    
    /// The mermaid child process to render the preview
    var mermaidRenderProcess: Process = Process()
    
    /// A file monitor to watch for changes in the preview
    private var fileMonitor: FileMonitor?
    
    /// The URL of the mermaid code file, of type `URL`
    public static var mermaidFileUrl: URL {
        let mermaidDirUrl: URL = Settings
            .cacheUrl
            .appendingPathComponent("MermaidRenderer")
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
    public static var previewFileUrl: URL {
        let mermaidDirUrl: URL = Settings
            .cacheUrl
            .appendingPathComponent("MermaidRenderer")
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
    
    /// A `Logger` object for the `DiagrammerViewController` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: MermaidRenderer.self)
    )
    
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
    
    /// Function to reset mermaid code
    public static func resetMermaidCode() {
        Self.saveMermaidCode(code: "")
    }
    
    /// Function to save the mermaid code
    public static func saveMermaidCode(
        code: String
    ) {
        // Save mermaid text to file
        do {
            try code.write(
                to: Self.mermaidFileUrl,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            Self.logger.error("Error saving mermaid code: \(error, privacy: .public)")
        }
    }
    
    /// Function to render the preview from the mermaid code
    public func render(
        attemptsRemaining: Int = 3,
        onFinish: (() -> Void)? = nil
    ) throws {
        // Add flag for finished rendering
        var didFinishRendering: Bool = false
        // Start the mermaid child process
        self.mermaidRenderProcess = Process()
        self.mermaidRenderProcess.executableURL = Bundle.main.resourceURL?.appendingPathComponent("mermaid-cli")
        let arguments = [
            "-log",
            Self.mermaidFileUrl.posixPath
        ]
        self.mermaidRenderProcess.arguments = arguments
        self.mermaidRenderProcess.standardInput = FileHandle.nullDevice
        // Capture stdout and stderr
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        self.mermaidRenderProcess.standardOutput = outputPipe
        self.mermaidRenderProcess.standardError = errorPipe
        var renderError: String?
        let renderErrorSemaphore = DispatchSemaphore(value: 0)
        do {
            // Setup monitor
            self.fileMonitor = try? FileMonitor(
                url: Self.previewFileUrl
            ) {
                didFinishRendering = true
                // Render
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.5
                ) {
                    self.fileMonitor = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                }
            }
            try self.mermaidRenderProcess.run()
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
                    if !didFinishRendering, attemptsRemaining == 0 {
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
    
}
