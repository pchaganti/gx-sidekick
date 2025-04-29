//
//  ServerArgument.swift
//  Sidekick
//
//  Created by John Bean on 4/29/25.
//

import Foundation

public struct ServerArgument: Identifiable, Codable {
    
    public var id: UUID = UUID()
    
    /// A `Bool` representing whether the argument is active
    public var isActive: Bool = true
    /// A `String` containing the flag
    public var flag: String
    /// A `String` containing a value corresponding to the flag
    public var value: String
    
    /// The arguments to be appended to `llama-server`
    public var arguments: [String] {
        var arguments: [String] = [self.flag]
        if !self.value.isEmpty {
            arguments.append(self.value)
        }
        return arguments
    }
    
    /// A list of default arguments
    public static let defaultServerArguments: [ServerArgument] = [
        ServerArgument(
            flag: "--top-k",
            value: "20"
        ),
        ServerArgument(
            flag: "--top-p",
            value: "0.95"
        ),
        ServerArgument(
            flag: "--min-p",
            value: "0"
        )
    ]
    
}
