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
	
	/// Test to check model reccomendations on different hardware
	@Test func checkModelReccomendations() async throws {
		DefaultModels.checkModelRecommendations()
	}
	
	/// Test sorting a directory
	@MainActor
	@Test func sortDirectory() async throws {
		// Get all files in directory
		let url: URL = URL(
			fileURLWithPath: "/Users/bj/Library/Application Support/Magic Sorter/Sorted Land/Geography DL/Y12"
		)
		guard let contents: [URL] = url.contents?.filter({
			!$0.hasDirectoryPath && !$0.lastPathComponent.hasPrefix(".") && !$0.lastPathComponent.hasPrefix("~$")
		}) else {
			return
		}
		print("Sorting \(contents.count) files")
		// Get summary
		let summaries: [FileToSort.FileSummary] = await contents.asyncMap { url in
			var file: FileToSort = FileToSort(
				url: url
			)
			return await file.getFileSummary()
		}
		let summary: String = summaries.map({ summary in
			return summary.toJSONString(prettyPrint: true) ?? nil
		}).compactMap({
			$0
		}).joined(separator: ", ")
		// Formulate prompt
		let prompt: String = """
Topic
--File 1.pdf
--File 2.docx
--Subtopic 1
----File 1.pptx
----Subsubtopic 1.1
------File 1.docx
----Subsubtopic 1.2
------File 1.pdf
------File 2.png
--Subtopic 2
----File 1.pdf
----File 2.pdf
--Subtopic 3
----File 1.pdf
----File 2.xlsx
----Subsubtopic 3.1
------File 1.docx

Following the structure outlined above, sort the files below into a directory structure based on their filename and content summary. Group files by subtopics aggressively.

Your response should ONLY include the new directory structure.

\(summary)
"""
		// Run inference to get sorting result
		let result: String = try await FileToSort.generate(
			prompt: prompt
		)
		print(result)
	}

}
