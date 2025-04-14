//
//  DefaultFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/7/25.
//

import ExtractKit_macOS
import Foundation
import FSKit_macOS

public protocol FunctionParams: Codable, Hashable {}

public class DefaultFunctions {
    
    static var functions: [AnyFunctionBox] = [
        DefaultFunctions.sum,
        DefaultFunctions.average,
        DefaultFunctions.multiply,
        DefaultFunctions.sumRange,
        DefaultFunctions.showAlert,
        DefaultFunctions.runJavaScript,
        DefaultFunctions.webSearch,
        DefaultFunctions.listDirectory,
        DefaultFunctions.extractFileText,
        DefaultFunctions.writePlaintextToFile,
        DefaultFunctions.deleteFile,
    ]
    
    /// A ``Function`` to show alerts
    static let showAlert = Function<ShowAlertParams, String?>(
        name: "show_alert",
        description: "Show an alert dialog to the user",
        params: [
            FunctionParameter(
                label: "message",
                description: "The message displayed in the alert",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            DispatchQueue.main.async {
                Dialogs.showAlert(
                    title: "Alert",
                    message: params.message
                )
            }
            return "An alert with the message \"\(params.message)\" was shown."
        }
    )
    struct ShowAlertParams: FunctionParams {
        let message: String
    }
    
    /// A ``Function`` for adding up 2 numbers
    static let sum = Function<SumParams, Float>(
        name: "sum",
        description: "Adds a maximum of 5 numbers together. All but the first number is optional.",
        params: [
            FunctionParameter(
                label: "a",
                description: "The first number to add",
                datatype: .float,
                isRequired: true
            ),
            FunctionParameter(
                label: "b",
                description: "The second number to add (optional)",
                datatype: .float,
                isRequired: false
            ),
            FunctionParameter(
                label: "c",
                description: "The third number to add (optional)",
                datatype: .float,
                isRequired: false
            ),
            FunctionParameter(
                label: "d",
                description: "The fourth number to add (optional)",
                datatype: .float,
                isRequired: false
            ),
            FunctionParameter(
                label: "e",
                description: "The fifth number to add (optional)",
                datatype: .float,
                isRequired: false
            )
        ],
        run: { params in
            return params.a + (params.b ?? 0) + (params.c ?? 0) + (params.d ?? 0) + (params.e ?? 0)
        }
    )
    struct SumParams: FunctionParams {
        var a: Float
        var b: Float? = nil
        var c: Float? = nil
        var d: Float? = nil
        var e: Float? = nil
    }
    
    /// A ``Function`` for getting the product of 2 numbers
    static let multiply = Function<MultiplyParams, Float>(
        name: "multiply",
        description: "Multiplies 2 numbers.",
        params: [
            FunctionParameter(
                label: "a",
                description: "The first number to multiply",
                datatype: .float,
                isRequired: true
            ),
            FunctionParameter(
                label: "b",
                description: "The second number to multiply",
                datatype: .float,
                isRequired: true
            )
        ],
        run: { params in
            return params.a * params.b
        }
    )
    struct MultiplyParams: FunctionParams {
        var a: Float
        var b: Float
    }
    
    /// A ``Function`` for getting the sum of all numbers within a range
    static let sumRange = Function<SumRangeParams, Int>(
        name: "sum_range",
        description: "Sums all integers between 2 integers, inclusive.",
        params: [
            FunctionParameter(
                label: "a",
                description: "The first number in the range",
                datatype: .integer,
                isRequired: true
            ),
            FunctionParameter(
                label: "b",
                description: "The second number in the range",
                datatype: .integer,
                isRequired: true
            )
        ],
        run: { params in
            return Array(params.a...params.b).reduce(0, +)
        }
    )
    struct SumRangeParams: FunctionParams {
        var a: Int
        var b: Int
    }
    
    /// A ``Function`` for getting the average of numbers
    static let average = Function<AverageParams, Float>(
        name: "average",
        description: "Calculates the average of an array of numbers.",
        params: [
            FunctionParameter(
                label: "numbers",
                description: "Array of numbers to calculate the average from",
                datatype: .floatArray,
                isRequired: true
            )
        ],
        run: { params in
            guard !params.numbers.isEmpty else {
                throw AverageError.noNumbers
            }
            return params.numbers.reduce(0, +) / Float(params.numbers.count)
            // Custom error for Average function
            enum AverageError: String, Error {
                case noNumbers = "No numbers were provided from which to calculate an average."
            }
        }
    )
    struct AverageParams: FunctionParams {
        var numbers: [Float]
    }
    
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
    
    /// A ``Function`` to conduct a web search
    static let webSearch = Function<WebSearchParams, String>(
        name: "web_search",
        description: "Retrieves information from the web with the provided query, instead of estimating it.",
        clearance: .sensitive,
        params: [
            FunctionParameter(
                label: "query",
                description: "The topic to look up online",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { param in
            // Check if enabled
            if !RetrievalSettings.canUseWebSearch {
                throw WebSearchError.notEnabled
            }
            // Conduct search
            let sources: [Source] = try await TavilySearch.search(
                query: param.query,
                resultCount: 3
            )
            // Convert to JSON
            let sourcesInfo: [Source.SourceInfo] = sources.map(\.info)
            let jsonEncoder: JSONEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted]
            let jsonData: Data = try! jsonEncoder.encode(sourcesInfo)
            let resultsText: String = String(
                data: jsonData,
                encoding: .utf8
            )!
            return resultsText
            // Custom error for Web Search function
            enum WebSearchError: String, Error {
                case notEnabled = "Web search has not been enabled in Settings."
            }
        }
    )
    struct WebSearchParams: FunctionParams {
        let query: String
    }
    
    /// A function to list files in a directory
    static let listDirectory = Function<ListDirectoryParams, [String]>(
        name: "list_directory",
        description: "Lists the files in a directory. Use the `recursive` parameter to list files in subdirectories recursively.\n\nThe user's home directory is `\(URL.homeDirectory.posixPath)`, their downloads directory is \(URL.downloadsDirectory.posixPath), and their desktop directory is \(URL.desktopDirectory.posixPath)",
        clearance: .sensitive,
        params: [
            FunctionParameter(
                label: "posixPath",
                description: "The POSIX path of the directory.",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "recursive",
                description: "Controls whether files in subdirectories are listed. (optional, defaults to true)",
                datatype: .boolean,
                isRequired: false
            )
        ],
        run: { params in
            // Check URL
            guard let url: URL = URL(filePath: params.posixPath) else {
                throw ListDirectoryError.invalidPath
            }
            if !url.fileExists {
                throw ListDirectoryError.pathNotFound
            }
            if !url.hasDirectoryPath {
                throw ListDirectoryError.notDirectory
            }
            // Fetch items
            let isRecursive: Bool = params.recursive ?? true
            let urls: [URL] = url.getContents(recursive: isRecursive) ?? []
            let paths: [String] = urls.map { url in
                return url.posixPath
            }
            return paths
            enum ListDirectoryError: String, Error {
                case invalidPath = "The provided POSIX path is not valid."
                case pathNotFound = "The specified path does not exist."
                case notDirectory = "The specified path is not a directory."
            }
        }
    )
    struct ListDirectoryParams: FunctionParams {
        var posixPath: String
        var recursive: Bool?
    }
    
    /// A function to extract the text from a file
    static let extractFileText = Function<ExtractFileTextParams, String>(
        name: "extract_file_text",
        description: "Extracts and outputs the contents of a file. Supports plain text, images, PDFs, Word documents, PowerPoints, Excel spreadsheets, and more file formats. OCR is used for images.",
        clearance: .dangerous,
        params: [
            FunctionParameter(
                label: "posixPath",
                description: "The POSIX path of the file.",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Check URL
            guard let url: URL = URL(filePath: params.posixPath) else {
                throw ExtractFileTextError.invalidPath
            }
            if !url.fileExists {
                throw ExtractFileTextError.pathNotFound
            }
            if !url.isFileURL {
                throw ExtractFileTextError.notFile
            }
            // Extract text
            let text = try await ExtractKit.shared.extractText(
                url: url,
                speed: .fast
            )
            return text
            enum ExtractFileTextError: String, Error {
                case invalidPath = "The provided POSIX path is not valid."
                case pathNotFound = "The file does not exist at the specified path."
                case notFile = "The specified path is not a file."
            }
        }
    )
    struct ExtractFileTextParams: FunctionParams {
        var posixPath: String
    }
    
    /// A function to write to a text file
    static let writePlaintextToFile = Function<WritePlaintextToFileParams, String?>(
        name: "write_plaintext_to_file",
        description: "Writes the provided text to a file at the specified POSIX path.",
        clearance: .sensitive,
        params: [
            FunctionParameter(
                label: "text",
                description: "The text to write to the file.",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "posixPath",
                description: "The POSIX path of the file.",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Check URL
            guard let url: URL = URL(filePath: params.posixPath) else {
                throw WriteToTxtFileError.invalidPath
            }
            // Write text
            try params.text.write(to: url, atomically: true, encoding: .utf8)
            return "The text was written successfully to the file at \(params.posixPath)."
            enum WriteToTxtFileError: String, Error {
                case invalidPath = "The provided POSIX path is not valid."
            }
        }
    )
    struct WritePlaintextToFileParams: FunctionParams {
        var text: String
        var posixPath: String
    }
    
    /// A function to delete a file
    static let deleteFile = Function<DeleteFileParams, String?>(
        name: "delete_file",
        description: "Deletes the file or directory at the specified POSIX path. Directories are deleted recursively.",
        clearance: .dangerous,
        params: [
            FunctionParameter(
                label: "posixPath",
                description: "The POSIX path of the file.",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Check URL
            guard let url: URL = URL(filePath: params.posixPath) else {
                throw ExtractFileTextError.invalidPath
            }
            if !url.fileExists {
                throw ExtractFileTextError.pathNotFound
            }
            // Delete the file
            FileManager.removeItem(at: url)
            return "The file at `\(params.posixPath)` was deleted successfully."
            enum ExtractFileTextError: String, Error {
                case invalidPath = "The provided POSIX path is not valid."
                case pathNotFound = "The file does not exist at the specified path."
            }
        }
    )
    struct DeleteFileParams: FunctionParams {
        var posixPath: String
    }
    
}
