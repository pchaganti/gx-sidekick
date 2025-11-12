//
//  PythonRunner.swift
//  Sidekick
//
//  Created by John Bean on 11/6/25.
//

import Foundation

/// A class to execute Python
public class PythonRunner {
    
    /// Function to execute Python and return the result
    /// - Parameter code: The Python code to be run
    /// - Returns: The result produced from the Python code
    public static func executePython(
        _ code: String
    ) throws -> String {
        // Create a temporary file for the Python code
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("python_\(UUID().uuidString).py")
        
        // Write code to temp file
        do {
            try code.write(to: tempFile, atomically: true, encoding: .utf8)
        } catch {
            throw PyError.executionFailed
        }
        
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        // Create a process to run Python through zsh
        let process = Process()
        
        // Use zsh to source ~/.zshrc and run Python
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // Source ~/.zshrc to get proper environment, then run Python
        // Let the shell resolve which python to use (don't hardcode path)
        let shellCommand = """
        source ~/.zshrc 2>/dev/null || true
        python3 '\(tempFile.path)' 2>&1 || python '\(tempFile.path)' 2>&1
        """
        
        process.arguments = ["-c", shellCommand]
        
        // Create pipes for output and error
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Run the process
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw PyError.executionFailed
        }
        
        // Check exit status
        let exitCode = process.terminationStatus
        
        // Read output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Read error
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Check for errors
        if exitCode != 0 {
            if !errorOutput.isEmpty {
                throw PyError.exception(error: errorOutput)
            } else {
                throw PyError.executionFailed
            }
        }
        
        // Return output if available
        if !output.isEmpty {
            return output
        } else if !errorOutput.isEmpty {
            // Sometimes warnings go to stderr but exit code is 0
            return errorOutput
        } else {
            throw PyError.couldNotObtainResult
        }
    }
    
    /// Enum for possible errors during Python execution
    public enum PyError: LocalizedError {
        
        case executionFailed
        case exception(error: String)
        case couldNotObtainResult
        
        public var errorDescription: String? {
            switch self {
                case .executionFailed:
                    return "Python execution failed"
                case .exception(let error):
                    return "Python execution failed: \(error)"
                case .couldNotObtainResult:
                    return "Python execution did not return a result"
            }
        }
    }
    
    // Helper function to check if Python is installed
    public static func isPythonInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "source ~/.zshrc 2>/dev/null || true; command -v python3 || command -v python"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        try? process.run()
        process.waitUntilExit()
        
        return process.terminationStatus == 0
    }
    
}
