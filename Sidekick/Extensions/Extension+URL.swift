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
		return self.absoluteString.hasPrefix("http") ||
		self.absoluteString.hasPrefix("https") ||
		self.absoluteString.hasPrefix("www")
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
	
	/// Function to verify if url is reachable
	static func verifyURL(
		urlPath: String,
		timeoutInterval: Double = 3,
		completion: @escaping (_ isValid: Bool) ->()
	) {
		if let url = URL(string: urlPath) {
			var request = URLRequest(
				url: url,
				timeoutInterval: timeoutInterval
			)
			request.httpMethod = "HEAD"
			let task = URLSession.shared.dataTask(
				with: request
			) { _, response, error in
				if let httpResponse = response as? HTTPURLResponse {
					if httpResponse.statusCode == 200 {
						completion(true)
					}
				} else {
					completion(false)
				}
			}
			task.resume()
		} else {
			completion(false)
		}
	}

}
