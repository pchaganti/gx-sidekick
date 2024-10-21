//
//  Profile.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SwiftUI

public struct Profile: Identifiable, Codable, Hashable, Sendable {
	
	/// Stored property for `Identifiable` conformance
	public var id: UUID = UUID()
	
	/// Stored property for the profile's name
	public var name: String
	
	/// Stored property for the profile's symbol name
	public var symbolName: String
	
	/// Stored property for profile color
	public var color: Color
	
	/// Computed property returning the profile's symbol
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
	
	/// Computed property returning the profile's label
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
	
	/// Computed property returning the profile's image
	public var image: some View {
		Image(systemName: symbolName)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.foregroundStyle(
				self.color
			)
	}
	
	/// Stored property for whether web search is used
	public var useWebSearch: Bool = true
	
	/// Stored property for the profile's associated resources
	public var resources: Resources = Resources()
	
	/// Stored property for system prompt (if customised)
	public var systemPrompt: String? = nil
	
	/// Stored property for whether the profile is persisted across sessions
	public var persistResources: Bool = true
	
	/// Static constant for the `default` profile
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
