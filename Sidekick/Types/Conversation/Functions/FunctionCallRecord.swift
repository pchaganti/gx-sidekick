//
//  FunctionCall.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation
import SwiftUI

public struct FunctionCallRecord: Codable, Equatable, Hashable {
    
    /// The function call's ID
    var id: UUID = UUID()
    /// A `String` for the name of the function called
    var name: String
    /// A ``Status`` representing if the function was executed successfully
    var status: Status? = .executing
    /// A `Date` for the time where the function was called
    var timeCalled: Date = .now
    /// A `String` containing the result of the run
    var result: String? = nil
    
    public enum Status: Codable, CaseIterable {
        
        case succeeded
        case failed
        case executing
        
        var color: Color {
            switch self {
                case .succeeded:
                    return .brightGreen
                case .failed:
                    return .red
                case .executing:
                    return .secondary
            }
        }
        
        /// A `Bool` representing whether the function has been executed
        var didExecute: Bool {
            switch self {
                case .succeeded, .failed:
                    return true
                case .executing:
                    return false
            }
        }
        
    }
    
}
