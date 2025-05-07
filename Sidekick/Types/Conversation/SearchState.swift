//
//  SearchState.swift
//  Sidekick
//
//  Created by John Bean on 5/7/25.
//

import Foundation

public enum SearchState: String, MenuOptions {
    
    case search
    case deepResearch
    
    public var id: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
            case .search:
                return String(localized: "Search")
            case .deepResearch:
                return String(localized: "Deep Research")
        }
    }
    
}
