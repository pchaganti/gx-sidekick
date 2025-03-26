//
//  CompletionsExclusionList.swift
//  Sidekick
//
//  Created by John Bean on 3/25/25.
//

import FSKit_macOS
import SwiftUI

struct CompletionsExclusionList: View {
	
	@Binding var isPresented: Bool
	
	@State private var completionsExcludedApps: [String] = Settings.completionsExcludedApps
	
	var body: some View {
		VStack(
			alignment: .leading
		) {
			List(
				self.$completionsExcludedApps,
				id: \.self
			) { appId in
				HStack {
					AppEditorField(appId: appId)
					Spacer()
					Button {
						// Remove from list
						withAnimation(.linear) {
							self.completionsExcludedApps = self.completionsExcludedApps.filter { name in
								return name != appId.wrappedValue
							}
						}
					} label: {
						Label("Delete", systemImage: "trash")
							.foregroundStyle(.red)
							.labelStyle(.iconOnly)
					}
					.buttonStyle(.plain)
				}
			}
			.frame(minHeight: 200, maxHeight: 300)
			Divider()
			HStack {
				Spacer()
				addButton
				doneButton
			}
			.controlSize(.large)
			.padding([.bottom, .trailing], 12)
		}
		.onAppear {
			completionsExcludedApps = Settings.completionsExcludedApps
		}
		.onDisappear {
			withAnimation(.linear) {
				// Filter and save
				self.filterAndSaveIds()
			}
		}
	}
	
	var addButton: some View {
		Button {
			// Add
			withAnimation(.linear) {
				self.addApp()
			}
		} label: {
			Text("Add")
		}
	}
	
	var doneButton: some View {
		Button {
			// Filter and save
			self.filterAndSaveIds()
			// Hide sheet
			self.isPresented.toggle()
		} label: {
			Text("Done")
		}
		.keyboardShortcut(.defaultAction)
	}
	
	/// Function to add an app
	private func addApp() {
		if let appUrls: [URL] = try? FileManager.selectFile(
			rootUrl: URL.applicationDirectory,
			dialogTitle: "Select an App",
			canSelectFiles: true,
			canSelectDirectories: false,
			allowMultipleSelection: true
		) {
			// Add each app to list
			for appUrl in appUrls {
				if let bundle: Bundle = Bundle(url: appUrl),
				   let id = bundle.bundleIdentifier {
					self.completionsExcludedApps.append(id)
				}
			}
		}
		// Filter and save
		self.filterAndSaveIds()
	}
	
	/// Function to filter and save non- blank bundle IDs
	private func filterAndSaveIds() {
		// Keep unique IDs
		self.completionsExcludedApps = Array(Set(self.completionsExcludedApps)).sorted()
		// Filter out blank bundle IDs
		self.completionsExcludedApps = self.completionsExcludedApps.filter { name in
			return !name.isEmpty
		}
		// Save
		Settings.completionsExcludedApps = self.completionsExcludedApps
	}
	
	struct AppEditorField: View {
		
		init(
			appId: Binding<String>
		) {
			self._appId = appId
			self.name = appId.wrappedValue
		}
		
		@Binding var appId: String
		@State private var name: String
		@FocusState	private var isFocused: Bool
		
		var body: some View {
			TextField("", text: self.$name)
				.focused(self.$isFocused)
				.textFieldStyle(.plain)
				.onChange(of: isFocused) {
					if isFocused {
						name = appId
					} else {
						appId = name
					}
				}
				.onSubmit {
					appId = name
				}
		}
		
	}
	
}
