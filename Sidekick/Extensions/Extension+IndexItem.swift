//
//  Extension+IndexItem.swift
//  Sidekick
//
//  Created by Bean John on 10/19/24.
//

import Foundation
import SimilaritySearchKit

public extension IndexItem {
	
	/// Computed property returning the result's source's URL
	var sourceUrl: URL? {
		guard let source: String = self.metadata["source"] else { return nil }
		return URL(string: source)
	}
	
	/// Computed property returning the result's source's URL text
	var sourceUrlText: String? {
		if sourceUrl?.isWebURL ?? false {
			return sourceUrl?.absoluteString
		}
		return sourceUrl?.posixPath
	}
	
	
	/// Computed property returning the result's source's index
	var itemIndex: Int? {
		guard let itemIndex: String = self.metadata["itemIndex"] else { return nil }
		return Int(itemIndex)
	}
	
}
