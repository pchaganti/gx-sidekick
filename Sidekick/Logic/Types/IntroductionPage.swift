//
//  IntroductionPage.swift
//  Sidekick
//
//  Created by Bean John on 12/17/24.
//

import Foundation
import SwiftUI

enum IntroductionPage: CaseIterable {
	
	case useProfiles
	case temporaryResources
	case webSearch
	case dataVisualization
	case inlineWritingAssistant
	case done
	
	/// A `Bool` indicating if there is a previous page
	public var hasPrevPage: Bool {
		return self.progress > 0
	}
	
	/// A `Bool` indicating if there is a next page
	public var hasNextPage: Bool {
		return self.progress < (Self.allCases.count - 1)
	}
	
	/// An array of ``Page`` indicating a sequence of pages
	private var pageSequence: [Self] {
		return (Self.allCases + Self.allCases)
	}
	
	/// An `Int` representing the page's number
	public var progress: Int {
		return self.pageSequence.firstIndex(of: self) ?? 0
	}
	
	/// A function to switch to the next page
	public mutating func nextPage() {
		withAnimation(.linear) {
			self = self.pageSequence[self.progress + 1]
		}
	}
	
	/// A function to switch to the previous page
	public mutating func prevPage() {
		let pageNumber: Int = self.pageSequence.lastIndex(of: self) ?? 0
		withAnimation(.linear) {
			self = self.pageSequence[pageNumber - 1]
		}
	}
	
	public var content: Content? {
		switch self {
			case .useProfiles:
				return Content(
					image: Image(.useProfiles),
					title: String(localized: "Profiles"),
					description: String(localized: "Create and use profiles to allow the chatbot to reply with **domain specific** information from your own files and folders.")
				)
			case .temporaryResources:
				return Content(
					image: Image(.temporaryResources),
					title: String(localized: "Temporary Resources"),
					description: String(localized: "Give the chatbot temporary access to a file by dropping it into the prompt field.")
				)
			case .webSearch:
				return Content(
					image: Image(.webSearch),
					title: String(localized: "Web Search"),
					description: String(localized: "Use Web Search to find up to date information about a topic.")
				)
			case .dataVisualization:
				return Content(
					image: Image(.dataVisualization),
					title: String(localized: "Data Visualization"),
					description: String(localized: "Visualizations are automatically generated for tables when appropriate, with a variety of charts available, including bar charts, line charts and pie charts.")
				)
			case .inlineWritingAssistant:
				return Content(
					image: Image(.inlineWritingAssistant),
					title: String(localized: "Inline Writing Assistant"),
					description: String(localized: "Press 'Command + Control + I' to access Sidekick's inline writing assistant. For example, use the 'Answer Question' command to do your homework without leaving Microsoft Word!")
				)
			default:
				return nil
		}
	}
	
	struct Content {
		
		var image: Image
		var title: String
		var description: String
		
	}
	
}
