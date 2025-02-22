//
//  ResourceSectionView.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import FSKit_macOS
import SwiftUI

struct ResourceSectionView: View {
	
	@Binding var profile: Profile
	
	@State private var isAddingWebsite: Bool = false
	
	@EnvironmentObject private var lengthyTasksController: LengthyTasksController
	
	var isUpdating: Bool {
		let taskName: String = String(
			localized: "Updating resource index for profile \"\(self.profile.name)\""
		)
		return lengthyTasksController.tasks
			.map(\.name)
			.contains(
				taskName
			)
	}
	
    var body: some View {
		Section {
			VStack {
				selectResources
				Divider()
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
				if isUpdating {
					ProgressView()
						.progressViewStyle(.circular)
						.scaleEffect(0.5)
				}
				Spacer()
				Button {
					Task.detached { @MainActor in
						self.add()
					}
				} label: {
					Text("Add")
				}
				.disabled(self.isUpdating)
				Button {
					Task.detached { @MainActor in
						await $profile.update()
					}
				} label: {
					Text("Update")
				}
				.disabled(self.isUpdating)
			}
			Divider()
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
			title: String(localized: "Do you want to add files, folders or webpages?"),
			option1: String(localized: "File/Folder"),
			option2: String(localized: "Webpage")
		) {
			addFile()
		} ifOption2: {
			isAddingWebsite.toggle()
		}
	}
	
	@MainActor
	private func addFile() {
		guard let selectedUrls: [URL] = try? FileManager.selectFile(
			dialogTitle: String(localized: "Select Files or Folders"),
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
				Text("Enter a link or URL:")
				TextField("Link or URL", text: $websiteUrl)
					.textFieldStyle(.roundedBorder)
				Divider()
				HStack {
					Spacer()
					Button {
						isAddingWebsite = false
					} label: {
						Text("Cancel")
					}
					Button {
						Task.detached { @MainActor in
							await add()
						}
					} label: {
						Text("Add")
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
