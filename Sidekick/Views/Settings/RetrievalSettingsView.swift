//
//  RetrievalSettingsView.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import SwiftUI

struct RetrievalSettingsView: View {
	
	@AppStorage("useTavilySearch") private var useTavilySearch: Bool = RetrievalSettings.useTavilySearch
	@State private var tavilyApiKey: String = RetrievalSettings.tavilyApiKey
	@State private var tavilyBackupApiKey: String = RetrievalSettings.tavilyBackupApiKey
	
	@State private var searchResultMultiplier: Int = RetrievalSettings.searchResultsMultiplier
	@State private var useSearchResultContext: Bool = RetrievalSettings.useSearchResultContext

    var body: some View {
		Form {
			Section {
				resourcesSearch
			} header: {
				Text("Resources Search")
			}
			Section {
				tavilySearch
			} header: {
				Text("Tavily Search")
			}
		}
		.formStyle(.grouped)
    }
	
	var tavilySearch: some View {
		Group {
			useSearch
			Group {
				tavilyApiKeyEditor
				tavilyBackupApiKeyEditor
			}
			.foregroundStyle(useTavilySearch ? .primary : .secondary)
		}
		.onAppear {
			self.useTavilySearch = RetrievalSettings.useTavilySearch
			self.tavilyApiKey = RetrievalSettings.tavilyApiKey
			self.tavilyBackupApiKey = RetrievalSettings.tavilyBackupApiKey
		}
	}
	
	var useSearch: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Use Tavily Search")
					.font(.title3)
					.bold()
				Text("Allow the chatbot to search the web for information relevant to user prompts")
					.font(.caption)
			}
			Spacer()
			Toggle("", isOn: $useTavilySearch.animation())
				.toggleStyle(.switch)
				.disabled(self.tavilyApiKey.isEmpty)
		}
	}
	
	var tavilyApiKeyEditor: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("API Key")
					.font(.title3)
					.bold()
				Text("Needed to access the Tavily API")
					.font(.caption)
				Button {
					let url: URL = URL(string: "https://app.tavily.com/home")!
					NSWorkspace.shared.open(url)
				} label: {
					Text("Get an API Key")
				}
			}
			.foregroundStyle(
				useTavilySearch && tavilyApiKey.isEmpty ? .red : .primary
			)
			Spacer()
			SecureField("", text: $tavilyApiKey)
                .textContentType(.password)
				.textFieldStyle(.roundedBorder)
				.frame(width: 300)
				.onChange(of: tavilyApiKey) { oldValue, newValue in
					RetrievalSettings.tavilyApiKey = newValue
				}
		}
	}
	
	var tavilyBackupApiKeyEditor: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Backup API Key (Optional)")
					.font(.title3)
					.bold()
				Text("Used to access the Tavily API if the main API key fails.")
					.font(.caption)
			}
			Spacer()
			SecureField("", text: $tavilyBackupApiKey)
				.textFieldStyle(.roundedBorder)
				.frame(width: 300)
				.onChange(
					of: tavilyBackupApiKey
				) { oldValue, newValue in
					RetrievalSettings.tavilyBackupApiKey = newValue
				}
		}
	}
	
	var resourcesSearch: some View {
		Group {
			searchResultCount
			searchResultContext
		}
	}
	
	var searchResultCount: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Search Results")
					.font(.title3)
					.bold()
				Text("Controls the number of search results from expert resources fed to the chatbot. The more results, the slower the chatbot will respond.")
					.font(.caption)
			}
			.frame(minWidth: 250)
			Spacer()
			Picker(selection: $searchResultMultiplier) {
				Text("Less")
					.tag(2)
				Text("Default")
					.tag(3)
				Text("More")
					.tag(4)
				Text("Most")
					.tag(6)
			}
			.pickerStyle(.segmented)
		}
		.onChange(of: searchResultMultiplier) {
			RetrievalSettings.searchResultsMultiplier = self.searchResultMultiplier
		}
	}
	
	var searchResultContext: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Search Result Context")
					.font(.title3)
					.bold()
				Text("Controls whether context of a search result is given to the chatbot. Turning this on will decrease generation speed, but will increase the length of each search result.")
					.font(.caption)
			}
			.frame(minWidth: 250)
			Spacer()
			Toggle("", isOn: $useSearchResultContext)
		}
		.onChange(of: useSearchResultContext) {
			RetrievalSettings.useSearchResultContext = self.useSearchResultContext
		}
	}
	
}
