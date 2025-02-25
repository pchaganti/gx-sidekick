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
	
	/// Computed property returning the expert's symbol, of type `View`
	public var symbol: some View {
		Image(systemName: symbolName)
			.padding(5)
			.foregroundStyle(
				self.color.adaptedTextColor
			)
			.background {
				Circle()
					.fill(self.color)
			}
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
	
	/// Computed property returning the expert's image, of type `View`
	public var image: some View {
		Image(systemName: symbolName)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.foregroundStyle(
				self.color
			)
	}
	
	/// Whether web search is used, of type `Bool`
	public var useWebSearch: Bool = true
	
	/// The expert's associated resources, of type `Resource`
	public var resources: Resources = Resources()
	
	/// The expert's system prompt (if customised), of type `String?`
	public var systemPrompt: String? = nil
	
	/// Controls whether the expert's resources is persisted across sessions, of type `Bool`
	public var persistResources: Bool = true
	
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
