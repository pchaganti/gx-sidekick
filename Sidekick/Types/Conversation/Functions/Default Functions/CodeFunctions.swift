//
//  CodeFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/14/25.
//

import Foundation

public class CodeFunctions {
    
    static var functions: [AnyFunctionBox] = [
        CodeFunctions.runJavaScript,
        CodeFunctions.runCommand
    ]
    
    /// A ``Function`` for running JavaScript
    static let runJavaScript = Function<RunJavaScriptParams, String>(
        name: "run_javascript",
        description: "Runs JavaScript code and returns the result. Useful for performing calculations with many steps or performing transformations on data.",
        params: [
            FunctionParameter(
                label: "code",
                description: "The JavaScript code to run",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            return try JavaScriptRunner.executeJavaScript(params.code)
        }
    )
    struct RunJavaScriptParams: FunctionParams {
        let code: String
    }
    
    /// A function to run a terminal command
    static let runCommand = Function<RunCommandParams, String?>(
        name: "run_command",
        description: "Executes the specified command in the macOS Terminal and returns the output.",
        clearance: .dangerous,
        params: [
            FunctionParameter(
                label: "command",
                description: "The shell command to execute.",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "workingDirectory",
                description: "The POSIX path of the working directory for command execution. Defaults to home directory `\(URL.homeDirectory.posixPath)` if not specified.",
                datatype: .string,
                isRequired: false
            )
        ],
        run: { params in
            let process = Process()
            let pipe = Pipe()
            // Configure the process
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", params.command]
            // Set working directory if provided
            if let workingDir = params.workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            } else {
                process.currentDirectoryURL = URL.homeDirectory
            }
            // Setup output pipe
            process.standardOutput = pipe
            process.standardError = pipe
            do {
                try process.run()
                process.waitUntilExit()
                // Get command output
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8) else {
                    throw CommandError.outputEncodingFailed
                }
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                throw CommandError.executionFailed(error.localizedDescription)
            }
            enum CommandError: Error {
                case executionFailed(String)
                case outputEncodingFailed
                var localizedDescription: String {
                    switch self {
                        case .executionFailed(let message):
                            return "Failed to execute command: \(message)"
                        case .outputEncodingFailed:
                            return "Failed to encode command output"
                    }
                }
            }
        }
    )
    struct RunCommandParams: FunctionParams {
        var command: String
        var workingDirectory: String?
    }
    
}
