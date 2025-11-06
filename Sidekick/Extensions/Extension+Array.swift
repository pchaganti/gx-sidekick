//
//  Extension+Array.swift
//  Sidekick
//
//  Created by John Bean on 3/17/25.
//

import Foundation

public extension Array where Element: Hashable {
    
    var mode: Element? {
        return self.reduce([Element: Int]()) {
            var counts = $0
            counts[$1] = ($0[$1] ?? 0) + 1
            return counts
        }.max { $0.1 < $1.1 }?.0
    }
    
    func previousElement(of element: Element) -> Element? {
        // Find the index of the given element
        if let index = firstIndex(of: element) {
            // Check if there is a previous element
            if index > 0 {
                return self[index - 1]
            }
        }
        // Return nil if the element is not found or is the first element
        return nil
    }
    
}

extension Array where Element == String {
    
    /// Sort model names by provider, then generation (old to new), then size (large to small)
    func sortedByModelSize() -> [String] {
        return self.sorted { model1, model2 in
            let provider1 = model1.modelProvider
            let provider2 = model2.modelProvider
            
            // First, sort by provider (alphabetically)
            if provider1 != provider2 {
                return provider1.localizedStandardCompare(provider2) == .orderedAscending
            }
            
            // Within same provider, sort by family/generation
            let family1 = model1.modelFamily
            let family2 = model2.modelFamily
            
            if family1 != family2 {
                let version1 = family1.familyVersion
                let version2 = family2.familyVersion
                
                // If both have version numbers, compare versions (ascending - old first)
                if version1 > 0 && version2 > 0 {
                    if version1 != version2 {
                        return version1 < version2
                    }
                }
                
                // Otherwise, fall back to alphabetical comparison
                return family1.localizedStandardCompare(family2) == .orderedAscending
            }
            
            // Within the same family, sort by parameter count (descending - big/expensive first)
            let params1 = model1.modelParameterCount
            let params2 = model2.modelParameterCount
            
            if params1 != params2 {
                return params1 > params2
            }
            
            // If parameter counts are equal, sort alphabetically (handles date stamps)
            return model1.localizedStandardCompare(model2) == .orderedAscending
        }
    }
    
}
