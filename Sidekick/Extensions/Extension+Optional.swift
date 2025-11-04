//
//  Extension+Optional.swift
//  Sidekick
//
//  Created by John Bean on 11/4/25.
//

import Foundation

extension Optional where Wrapped: Collection {
    
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
    
}
