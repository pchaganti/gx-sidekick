//
//  Extension+SimilarityIndex.swift
//  Sidekick
//
//  Created by Bean John on 10/12/24.
//

import Foundation
import SimilaritySearchKit
import SimilaritySearchKitDistilbert

public extension SimilarityIndex {
	
	/// Function to search similarity index
	func search(
		query: String,
		maxResults: Int,
        threshold: Float = 0.6
	) async -> [Sidekick.SearchResult] {
		// Search
		let results: [SimilaritySearchKit.SearchResult] = await self.search(
			query,
			top: maxResults,
			metric: CosineSimilarity()
		)
		// Set similarity threshhold
		// For cosine similarity, a value of -1 indicates maximum distance, and a value of 1 indicates that the vectors are identical
		let similarResults: [Sidekick.SearchResult] = results.filter { result in
			return result.score >= threshold
		}.map { result in
			Sidekick.SearchResult(searchResult: result)
		}.filter({ $0.sourceUrl != nil })
		return similarResults
	}
	
}
