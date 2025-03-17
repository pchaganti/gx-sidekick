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
	
}
