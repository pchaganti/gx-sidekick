//
//  DefaultFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/7/25.
//

import Foundation

import Foundation

// Parameter structs that conform to Codable
struct ShowAlertParams: Codable {
    let message: String
}

struct JoinParams: Codable {
    let front: String
    let end: String
}

// Updated parameter structs using the property wrapper to decode numbers that may be strings.
struct AddParams: Codable {
    @StringOrNumber var a: Float
    @OptionalStringOrNumber var b: Float?
}

struct MultiplyParams: Codable {
    @StringOrNumber var a: Float
    @StringOrNumber var b: Float
}

struct AverageParams: Codable {
    @StringOrArray var numbers: [Float]
}

struct RunJavaScriptParams: Codable {
    let code: String
}

public class DefaultFunctions {
    
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
            return nil
        }
    )
    
    /// A ``Function`` to join 2 strings
    static let join = Function<JoinParams, String>(
        name: "join",
        description: "Joins two strings.",
        params: [
            FunctionParameter(
                label: "front",
                description: "The first string, which goes in front",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "end",
                description: "The second string, which goes at the end",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            return params.front + params.end
        }
    )
    
    /// A ``Function`` for adding up 2 numbers
    static let add = Function<AddParams, Float>(
        name: "sum",
        description: "Adds two numbers together. The second number is optional.",
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
            )
        ],
        run: { params in
            return params.a + (params.b ?? 0)
        }
    )
    
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
    
    
    /// A ``Function`` for running JavaScript
    static let runJavaScript = Function<RunJavaScriptParams, String>(
        name: "run_javascript",
        description: "Runs the JavaScript code provided and returns the result",
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
    
}
