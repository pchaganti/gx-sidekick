//
//  Extension+URL.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation

public extension URL {
	
	/// A `Bool` representing iif the URL is a web URL
	var isWebURL: Bool {
		return self.absoluteString.hasPrefix("http://") ||
		self.absoluteString.hasPrefix("https://") ||
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
		url: URL,
		timeoutInterval: Double = 3,
		completion: @escaping (_ isValid: Bool) ->()
	) {
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
	}
	
	/// Function to check if a url is reachable
	func isReachable() async -> Bool {
		do {
			// Create a URL session with a data task
			let (_, response) = try await URLSession.shared.data(from: self)
			// Check if the response is an HTTPURLResponse and has a status code in the 200-299 range
			if let httpResponse = response as? HTTPURLResponse,
				(200...299).contains(httpResponse.statusCode) {
				return true
			} else {
				print("Failed to get HTTP response")
				return false
			}
		} catch {
			print("Error checking URL reachability: \(error)")
			return false
		}
	}
	
	/// Function to check if an API endpoint is reachable
	func isAPIEndpointReachable(
		method: String = "GET",
		timeout: TimeInterval = 3.0
	) async -> Bool {
        // Formulate request
		var request = URLRequest(url: self)
		request.httpMethod = method
		request.timeoutInterval = timeout
        // Attach API Key
        request.setValue(
            "Bearer \(InferenceSettings.inferenceApiKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = timeout
        session.configuration.timeoutIntervalForResource = timeout
        do {
			let (data, response) = try await URLSession.shared.data(for: request)
			guard let httpResponse = response as? HTTPURLResponse else {
				return false
			}
			return (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 400
		} catch {
			return false
		}
	}
	
	/// A  `String` without the schema (e.g., removes `https://` from `https://example.com`).
	var withoutSchema: String {
		guard let schemeEnd = self.absoluteString.range(of: "://")?.upperBound else {
			// If no schema is found, return the entire string
			return self.absoluteString
		}
		// Extract the substring starting after the "://"
		return String(self.absoluteString[schemeEnd...])
	}

}
