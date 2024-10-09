//
//  Extension+URL.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation

public extension URL {
	
	/// Computed property returning if URL is a web URL
	var isWebURL: Bool {
		return self.scheme == "http" || self.scheme == "https"
	}
	
	/// Function to get all files one level deep
	func getContentsOneLevelDeep() -> [URL]? {
		// If no directory
		guard self.hasDirectoryPath else {
			return nil
		}
		// Enumerate directory
		var files = [URL]()
		if let enumerator = FileManager.default.enumerator(
			at: url,
			includingPropertiesForKeys: [],
			options: [
				.skipsHiddenFiles,
				.skipsSubdirectoryDescendants
			]
		) {
			for case let url as URL in enumerator {
				files.append(url)
			}
		}
		return files
	}

}
