//
//  Extension+EKEvent.swift
//  Sidekick
//
//  Created by John Bean on 4/17/25.
//

import EventKit
import Foundation

extension EKEventAvailability {
    
    var description: String? {
        switch self {
            case .busy:
                return "Busy"
            case .free:
                return "Free"
            case .tentative:
                return "Tenative"
            case .unavailable:
                return "Unavailable"
            @unknown default:
                return nil
        }
    }
    
}


extension EKEventStatus {
    
    var description: String? {
        switch self {
            case .confirmed:
                return "Confirmed"
            case .tentative:
                return "Tentative"
            case .canceled:
                return "Canceled"
            @unknown default:
                return nil
        }
    }
    
}
