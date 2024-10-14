//
//  ResourceSectionView.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import SwiftUI

struct ResourceSectionView: View {
	
	@Binding var profile: Profile
	
	@State private var isAddingWebsite: Bool = false
	
    var body: some View {
		Section {
			VStack {
				selectResources
				persistResources
			}
			.padding(.horizontal, 5)
		} header: {
			Text("Resources")
		}
		.sheet(isPresented: $isAddingWebsite) {
			WebsiteSelectionView(
				profile: $profile,
				isAddingWebsite: $isAddingWebsite
			)
		}
    }
	
	var selectResources: some View {
		VStack(alignment: .leading) {
			HStack {
				VStack(alignment: .leading) {
					Text("Resources: \(profile.resources.resources.count)")
						.font(.title3)
						.bold()
					Text("Files, folders or websites stored in the chatbot's \"conscience\"")
						.font(.caption)
				}
				Spacer()
				Button("Add") {
					self.add()
				}
				Button("Update") {
					Task.detached { @MainActor in
						await $profile.update()
					}
				}
			}
			ResourceSelectionView(profile: $profile)
		}
	}
	
	var persistResources: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Persist Resources")
					.font(.title3)
					.bold()
				Text("Keep resources between sessions")
					.font(.caption)
			}
			Spacer()
			Toggle("", isOn: $profile.persistResources)
				.toggleStyle(.switch)
		}
	}
	
	@MainActor
	private func add() {
		let _ = Dialogs.dichotomy(
			title: "Do yo want to add files, folders or websites?",
			option1: "File/Folder",
			option2: "Website") {
				addFile()
			} ifOption2: {
				isAddingWebsite.toggle()
			}
	}
	
	@MainActor
	private func addFile() {
		guard let selectedUrls: [URL] = try? FileManager.selectFile(
			dialogTitle: "Select Files or Folders",
			allowMultipleSelection: true
		) else { return }
		let resources: [Resource] = selectedUrls.map({
			Resource(url: $0)
		})
		Task.detached { @MainActor in
			await $profile.addResources(resources)
		}
	}
	
	struct WebsiteSelectionView: View {
		
		@Binding var profile: Profile
		@Binding var isAddingWebsite: Bool
		
		@State private var websiteUrl: String = ""
		
		var isValidUrl: Bool {
			// Check if init possible
			if URL(string: websiteUrl) == nil { return false }
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
				Text("Enter a link or URL:")
				TextField("Link or URL", text: $websiteUrl)
					.textFieldStyle(.roundedBorder)
				Divider()
				HStack {
					Spacer()
					Button("Cancel") {
						isAddingWebsite = false
					}
					Button("Add") {
						Task.detached { @MainActor in
							await add()
						}
					}
					.disabled(!isValidUrl)
					.keyboardShortcut(.defaultAction)
				}
			}
			.padding()
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
			await $profile.addResource(newResource)
		}
		
	}
	
}


//#Preview {
//    ResourceSectionView()
//}
