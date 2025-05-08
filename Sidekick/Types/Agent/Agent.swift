//
//  Agent.swift
//  Sidekick
//
//  Created by John Bean on 5/8/25.
//

import Foundation
import SwiftUI

public protocol Agent: ObservableObject {
    
    /// A `String` containing the name of the agent
    var name: String { get }
    
    /// A `View` to display agent progress to users
    var preview: AnyView { get }
    
    /// Function to begin the agentic loop
    func run() async throws -> LlamaServer.CompleteResponse
    
}
