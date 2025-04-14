//
//  Extension+CNContactStore.swift
//  Sidekick
//
//  Created by John Bean on 4/14/25.
//

import Contacts
import Foundation

public extension CNContactStore {
    
    // Helper function to wrap the CNContactStore requestAccess call in async/await.
    static func requestContactsAccess(using store: CNContactStore) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
}
