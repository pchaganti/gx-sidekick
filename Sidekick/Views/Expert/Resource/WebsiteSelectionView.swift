//
//  WebsiteSelectionView.swift
//  Sidekick
//
//  Created by John Bean on 3/17/25.
//

import SwiftUI

struct WebsiteSelectionView: View {
	
	@Binding var expert: Expert
	@Binding var isAddingWebsite: Bool
	
	@State private var websiteUrl: String = ""
	
	var isValidUrl: Bool {
		// Check if init possible
		guard let url = URL(string: websiteUrl) else { return false }
		// Check if web url
		if !url.isWebURL { return false }
		// Check format
		if NSURL(string: websiteUrl) == nil { return false }
		let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
		if let match = detector.firstMatch(
			in: websiteUrl,
			options: [],
			range: NSRange(
				location: 0,
				length: websiteUrl.utf16.count
			)
		) {
			// it is a link, if the match covers the whole string
			return match.range.length == websiteUrl.utf16.count
		} else {
			return false
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text("Enter a link or URL:")
					.font(.headline)
				Spacer()
				Button {
					isAddingWebsite = false
				} label: {
					Text("Cancel")
				}
				Button {
					Task { @MainActor in
						await add()
					}
				} label: {
					Text("Add")
				}
				.disabled(!isValidUrl)
				.keyboardShortcut(.defaultAction)
			}
			TextField("Link or URL", text: $websiteUrl)
				.textFieldStyle(.roundedBorder)
		}
		.padding(11)
		.padding([.horizontal, .top], 1)
	}
	
	private func add() async {
		if websiteUrl.last == "/" {
			websiteUrl = String(websiteUrl.dropLast())
		}
		guard let url = URL(string: websiteUrl) else { return }
		let newResource: Resource = Resource(
			url: url
		)
		isAddingWebsite = false
		await $expert.addResource(newResource)
	}
	
}
