//
//  ImageSearch.swift
//  Sidekick
//
//  Created by John Bean on 2/27/25.
//

import Foundation

public class ImageSearch {
	
	public struct CommonsImage: Codable {
		
		let title: String
		let urlString: String
		
		var url: URL {
			return URL(string: self.urlString)!
		}
		
		public enum CodingKeys: String, CodingKey {
			case title
			case urlString = "url"
		}
		
	}
	
	public struct QueryResult: Codable {
		let query: QueryData?
	}
	
	public struct QueryData: Codable {
		let allimages: [CommonsImage]?
	}
	
	/// Function to search Wikimedia Commons for images
	public static func searchCommonsImages(
		searchTerm: String,
		count: Int = 10
	) async throws -> [CommonsImage] {
		// Formulate the URL to send the request
		let urlString: String = "https://commons.wikimedia.org/w/api.php?action=query&format=json&list=allimages&aiprefix=\(searchTerm.capitalized)&ailimit=\(count)&prop=imageinfo&iiprop=url"
		guard let url = URL(string: urlString) else {
			throw URLError(.badURL)
		}
		// Send the request
		let (data, _) = try await URLSession.shared.data(from: url)
		// Obtain results
		do {
			let result = try JSONDecoder().decode(QueryResult.self, from: data)
			return result.query?.allimages ?? []
		} catch {
			throw error
		}
	}
	
}
