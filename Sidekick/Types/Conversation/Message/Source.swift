//
//  Source.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import Foundation
import SimilaritySearchKit

public struct Source: Identifiable, Codable, Hashable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The text in the source
	public var text: String
	
	/// The name of the source
	public var source: String
    
    /// The info associated with the source
    public var info: SourceInfo {
        return .init(url: self.source, text: self.text)
    }
    
    /// The content associated with the source
    public func getContent(
        transform: (String) -> String = { return $0 }
    ) async throws -> SourceContent {
        // Get content
        var content: String = try await WebScrape.scrape(
            url: self.source
        ).removingBase64Images()
        content = transform(content)
        // Return
        return SourceContent(url: self.source, content: content)
    }
    
    public struct SourceInfo: Codable {
        public var url: String
        public var text: String
    }
    
    public struct SourceContent: Codable {
        public var url: String
        public var content: String
    }
	
    /// Function to append previous and next items to a source
    public static func appendSourceContext(
        index: Int,
        text: String,
        sourceUrlText: String,
        similarityIndex: SimilarityIndex
    ) -> Source {
        // Get items in the same file
        let sameFileItems: [IndexItem] = similarityIndex.indexItems.filter {
            $0.sourceUrlText == sourceUrlText
        }
        // Get pre & post content
        let preContent: String = sameFileItems.filter({
            $0.itemIndex == index - 1
        }).first?.text ?? ""
        let postContent: String = sameFileItems.filter({
            $0.itemIndex == index + 1
        }).first?.text ?? ""
        // Make final text
        let fullText: String = [preContent, text, postContent].joined(separator: " ")
        return Source(
            text: fullText,
            source: sourceUrlText
        )
    }
    
}

public struct Sources: Identifiable, Codable, Hashable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The `UUID` of the message the souces are related to
	public var messageId: UUID
	/// An array of type ``Source``
	public var sources: [Source]
	
}
