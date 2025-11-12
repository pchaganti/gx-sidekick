//
//  StartupMetrics.swift
//  Sidekick
//
//  Created by John Bean on 11/12/25.
//

import Foundation
import OSLog

enum StartupMetrics {
    
    private static let subsystem: String = Bundle.main.bundleIdentifier ?? "com.pattonium.Sidekick"
    static let log = OSLog(subsystem: subsystem, category: "Startup")
    
    @discardableResult
    static func begin(_ name: StaticString) -> OSSignpostID {
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: signpostID)
        return signpostID
    }
    
    static func end(_ name: StaticString, _ signpostID: OSSignpostID) {
        os_signpost(.end, log: log, name: name, signpostID: signpostID)
    }
    
    static func event(_ name: StaticString) {
        os_signpost(.event, log: log, name: name)
    }
    
}

