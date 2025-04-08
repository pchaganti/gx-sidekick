//
//  DefaultFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/7/25.
//

import Foundation

public class DefaultFunctions {
    
    /// A list of default tools provided to the LLM
    static let tools: [any FunctionProtocol] = [
        DefaultFunctions.addFunction,
        DefaultFunctions.averageFunction
    ]
    
    /// A ``Function`` for adding up numbers
    static let addFunction: Function = Function<(Float, Float?), Float>(
        name: "sum",
        description: "Adds two numbers together. Second number is optional.",
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
        run: { a, b in
            return a + (b ?? 0)
        }
    )
    
    // Initialize the multiply function
    let multiplyFunction = Function<(Float, Float), Float>(
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
        run: { a, b in
            return a * b
        }
    )
    
    /// A ``Function`` for getting the average of numbers
    static let averageFunction = Function<[Float], Float>(
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
        run: { numbers in
            guard !numbers.isEmpty else { return 0 }
            return numbers.reduce(0, +) / Float(numbers.count)
        }
    )
    
}
