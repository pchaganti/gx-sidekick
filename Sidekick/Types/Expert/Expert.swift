//
//  Expert.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SwiftUI

/// An object that manages a chatbot expert
public struct Expert: Identifiable, Codable, Hashable, Sendable {
    
    /// Stored property for `Identifiable` conformance
    public var id: UUID = UUID()
    
    /// The expert's name, of type `String`
    public var name: String
    
    /// The expert's symbol name, of type `String`
    public var symbolName: String
    
    /// The expert's color of type `Color`
    public var color: Color
    
    /// Computed property returning the expert's icon, of type `View`
    public var icon: some View {
        ZStack {
            Circle()
                .fill(self.color)
                .frame(width: 25)
            Image(systemName: self.symbolName)
                .foregroundStyle(self.color.adaptedTextColor)
                .font(.system(size: 14))
                .shadow(
                    color: .secondary.opacity(0.3),
                    radius: 2, x: 0, y: 0.5
                )
        }
        .clipShape(Circle())
    }
    
    /// Computed property returning the expert's label, of type `View`
    public var label: some View {
        Label(self.name, systemImage: symbolName)
            .labelStyle(.titleAndIcon)
            .bold()
            .padding(7)
            .padding(.horizontal, 2)
            .foregroundStyle(
                self.color.adaptedTextColor
            )
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(self.color)
            }
    }
    
    /// Whether web search is used, of type `Bool`
    public var useWebSearch: Bool = true
    
    /// The expert's associated resources, of type `Resource`
    public var resources: Resources = Resources()
    
    /// The expert's system prompt (if customised), of type `String?`
    public var systemPrompt: String? = nil
    
    /// Controls whether the expert's resources is persisted across sessions, of type `Bool`
    public var persistResources: Bool = true
    
    /// Whether Graph RAG is enabled for this expert
    public var useGraphRAG: Bool {
        get { return resources.useGraphRAG }
        set { resources.useGraphRAG = newValue }
    }
    
    /// A `Bool` representing whether the expert is the default expert
    public var isDefault: Bool {
        return self == ExpertManager.shared.default
    }
    
    /// The `default` expert of type ``Expert``
    public static let `default`: Expert = Expert(
        name: String(localized: "Default"),
        symbolName: "person.fill",
        color: Color.blue,
        useWebSearch: false,
        resources: Resources(),
        persistResources: false
    )
    
    /// Stub for `Equatable` conformance
    public static func == (lhs: Expert, rhs: Expert) -> Bool {
        lhs.id == rhs.id
    }
    
}
