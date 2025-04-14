//
//  Extension+LSContext.swift
//  Sidekick
//
//  Created by John Bean on 4/14/25.
//

import Foundation
import LocalAuthentication

extension LAContext {
    
    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason reason: String
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            LAContext().evaluatePolicy(
                policy,
                localizedReason: reason
            ) { result, error in
                if let error = error { return cont.resume(throwing: error) }
                cont.resume(returning: result)
            }
        }
    }
}
