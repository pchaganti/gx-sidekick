//
//  Extension+SecureDefaults.swift
//  Sidekick
//
//  Created by John Bean on 3/11/25.
//

import Foundation
import SecureDefaults

public extension SecureDefaults {
	
	/// Function that returns secure defaults obkect
	static func defaults() -> SecureDefaults {
		// Init secure defaults object
		let defaults: SecureDefaults = SecureDefaults.shared
		if !defaults.isKeyCreated {
			defaults.password = UUID().uuidString
		}
		return defaults
	}
	
}
