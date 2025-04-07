//
//  DefaultTools.swift
//  Sidekick
//
//  Created by John Bean on 4/7/25.
//

import Foundation

public class DefaultTools {
    
    /// A list of default tools provided to the LLM
    static let tools: [any ToolProtocol] = [
        DefaultTools.addTool,
        DefaultTools.averageTool
    ]
    
    /// A ``Tool`` for adding up numbers
    static let addTool: Tool = Tool<(Float, Float?), Float>(
        name: "sum",
        description: "Adds two numbers together. Second number is optional.",
        params: [
            ToolParameter(
                label: "a",
                description: "The first number to add",
                datatype: .float,
                isRequired: true
            ),
            ToolParameter(
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
    
    /// A ``Tool`` for getting the average of numbers
    static let averageTool = Tool<[Float], Float>(
        name: "average",
        description: "Calculates the average of an array of numbers.",
        params: [
            ToolParameter(
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
