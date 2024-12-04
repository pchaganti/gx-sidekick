//
//  SidekickTests.swift
//  SidekickTests
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import Testing
@testable import Sidekick

struct SidekickTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
	
	/// Test to check model reccomendations on different hardware
	@Test func checkModelReccomendations() async throws {
		DefaultModels.checkModelRecommendations()
	}
	
	/// Test scraping file content, rename and summarize
	@MainActor
	@Test func summarizeFileContent() async throws {
		let url: URL = URL(
			fileURLWithPath: "/Users/bj/Library/Application Support/Magic Sorter/Sorted Land/Geography DL/Y12"
		)
		guard let contents: [URL] = url.contents?.filter({
			!$0.hasDirectoryPath
		}) else {
			return
		}
		for content in contents {
			var file: FileToSort = FileToSort(
				url: content
			)
			await file.scrapeContent()
			await file.generateSummary()
			if let summary: String = file.contentSummary {
				print("{\n\"filename\": \"\(content.lastPathComponent)\",\n\"content\": \"\(summary)\"\n},")
			}
		}
	}

}
