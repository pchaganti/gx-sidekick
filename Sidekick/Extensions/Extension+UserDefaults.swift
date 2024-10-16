//
//  Extension+UserDefaults.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import Foundation

public extension UserDefaults {
	
	/// Function to check if a key exists
	func exists(key: String) -> Bool {
		return UserDefaults.standard.object(forKey: key) != nil
	}
	
}
