//
//  Profile.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SwiftUI

/// An object that manages a chatbot profile
public struct Profile: Identifiable, Codable, Hashable, Sendable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// The profile's name of type `String`
	public var name: String
	
	/// The profile's symbol name of type `String`
	public var symbolName: String
	
	/// The profile's color of type `Color`
	public var color: Color
	
	/// Computed property returning the profile's symbol of type `View`
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
	
	/// Computed property returning the profile's label of type ``View``
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
	
	/// Computed property returning the profile's image of type `View`
	public var image: some View {
		Image(systemName: symbolName)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.foregroundStyle(
				self.color
			)
	}
	
	/// Whether web search is used of type `Bool`
	public var useWebSearch: Bool = true
	
	/// The profile's associated resources of type `Resource`
	public var resources: Resources = Resources()
	
	/// The profile's system prompt (if customised) of type `String?`
	public var systemPrompt: String? = nil
	
	/// Stored property for whether the profile is persisted across sessions
	public var persistResources: Bool = true
	
	/// Static constant for the `default` profile of type ``Profile``
	public static let `default`: Profile = Profile(
		name: String(localized: "Default"),
		symbolName: "person.fill",
		color: Color.blue,
		resources: Resources(),
		persistResources: false
	)
	
	public static func == (lhs: Profile, rhs: Profile) -> Bool {
		lhs.id == rhs.id
	}
	
}
