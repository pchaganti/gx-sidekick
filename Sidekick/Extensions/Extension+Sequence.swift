//
//  Extension+Sequence.swift
//  Sidekick
//
//  Created by John Bean on 11/4/25.
//

import Foundation

public extension Sequence {
    
    func sorted<T: Comparable>(
        by keyPath: KeyPath<Element, T>
    ) -> [Element] {
        return sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
    
    func map<T>(
        keyPath: KeyPath<Element, T>
    ) -> [T] {
        return map { $0[keyPath: keyPath] }
    }
    
    func concurrentMap<T>(
        _ transform: @escaping (Element) async -> T
    ) async -> [T] {
        await withTaskGroup(of: (Int, T).self) { group in
            for (index, element) in self.enumerated() {
                group.addTask {
                    (index, await transform(element))
                }
            }
            
            var results: [(Int, T)] = []
            for await result in group {
                results.append(result)
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, element) in self.enumerated() {
                group.addTask {
                    (index, try await transform(element))
                }
            }
            
            var results: [(Int, T)] = []
            for try await result in group {
                results.append(result)
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    func asyncMap<T>(
        _ transform: @escaping (Element) async -> T
    ) async -> [T] {
        var results: [T] = []
        for element in self {
            await results.append(transform(element))
        }
        return results
    }
    
    func asyncMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        var results: [T] = []
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }
    
}

