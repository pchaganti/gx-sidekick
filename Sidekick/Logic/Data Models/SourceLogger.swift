//
//  SourceLogger.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import Foundation

public class SourceLogger {
	
	/// Function to log a source
	public static func log(sources: String) {
		try? sources.write(
			to: Self.logUrl,
			atomically: true,
			encoding: .utf8
		)
	}
	
	/// Computed property returning the log file's URL
	private static var logUrl: URL {
		return URL.applicationSupportDirectory.appendingPathComponent(
			"sources.txt"
		)
	}
	
}
