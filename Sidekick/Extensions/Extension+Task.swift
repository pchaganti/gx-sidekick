//
//  Extension+Task.swift
//  Sidekick
//
//  Created by John Bean on 11/11/25
//

import Foundation

/// Execute an async operation with a timeout
/// - Parameters:
///   - seconds: Timeout duration in seconds
///   - operation: The async operation to execute
/// - Returns: The result of the operation, or nil if timeout occurs
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        // Add the actual operation
        group.addTask {
            try? await operation()
        }
        
        // Add timeout task
        group.addTask {
            try? await Task.sleep(for: .seconds(seconds))
            return nil
        }
        
        // Return the first result
        if let result = await group.next() {
            group.cancelAll()
            return result
        }
        
        return nil
    }
}

