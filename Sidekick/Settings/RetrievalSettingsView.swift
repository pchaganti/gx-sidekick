//
//  RetrievalSettingsView.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import SwiftUI

struct RetrievalSettingsView: View {
	
	@State private var useTavilySearch: Bool = RetrievalSettings.useTavilySearch
	@State private var apiKey: String = RetrievalSettings.apiKey
	@State private var backupApiKey: String = RetrievalSettings.backupApiKey
	
    var body: some View {
		Form {
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
				apiKeyEditor
				backupApiKeyEditor
			}
			.foregroundStyle(useTavilySearch ? .primary : .secondary)
			.disabled(!useTavilySearch)
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
		}
		.onChange(of: useTavilySearch) {
			RetrievalSettings.useTavilySearch = self.useTavilySearch
		}
	}
	
	var apiKeyEditor: some View {
		HStack(alignment: .top) {
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
				useTavilySearch && apiKey.isEmpty ? .red : .primary
			)
			Spacer()
			VStack(alignment: .trailing) {
				SecureField("", text: $apiKey)
					.textFieldStyle(.plain)
				Button {
					RetrievalSettings.apiKey = self.apiKey
				} label: {
					Text("Save")
				}
			}
		}
	}
	
	var backupApiKeyEditor: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Backup API Key (Optional)")
					.font(.title3)
					.bold()
				Text("Used to access the Tavily API if the main API key fails.")
					.font(.caption)
			}
			Spacer()
			VStack(alignment: .trailing) {
				SecureField("", text: $backupApiKey)
					.textFieldStyle(.plain)
				Button {
					RetrievalSettings.backupApiKey = self.backupApiKey
				} label: {
					Text("Save")
				}
			}
		}
	}
	
}

//#Preview {
//    RetrievalSettingsView()
//}
