//
//  Memory.swift
//  Sidekick
//
//  Created by John Bean on 4/22/25.
//

import Foundation
import SimilaritySearchKit
import SimilaritySearchKitDistilbert

public struct Memory: Identifiable, Equatable, Codable {
    
    init?(
        messageId: UUID,
        text: String
    ) async {
        let id: UUID = UUID()
        self.id = id
        self.messageId = messageId
        self.createdAt = Date.now
        // Get index item
        let similarityIndex: SimilarityIndex = await SimilarityIndex(
            model: DistilbertEmbeddings(),
            metric: CosineSimilarity()
        )
        await similarityIndex.addItem(
            id: id.uuidString,
            text: text,
            metadata: ["date" : Date.now.formatted(date: .complete, time: .shortened)]
        )
        if let indexItem = similarityIndex.indexItems.first {
            self.indexItem = indexItem
        } else {
            return nil
        }
    }
    
    /// Stored property for `Identifiable` conformance
    public var id: UUID
    
    /// The `UUID` of the message from which the memory was derived
    public var messageId: UUID
    
    /// The `Date` on which the ``Memory`` was remembered
    public var createdAt: Date
    
    /// The `String` containing the memory
    public var text: String {
        return self.indexItem.text
    }
    
    /// The ``IndexItem`` of the memory
    public var indexItem: IndexItem
    
}

extension SimilarityIndex.IndexItem: @retroactive Equatable {
    
    public static func == (lhs: SimilarityIndex.IndexItem, rhs: SimilarityIndex.IndexItem) -> Bool {
        return lhs.id == rhs.id
    }
    
}
