//
//  RetrievalSettingsView.swift
//  Sidekick
//
//  Created by Bean John on 10/16/24.
//

import SwiftUI

struct RetrievalSettingsView: View {
    
    @Environment(\.openWindow) var openWindow
    
    @AppStorage("useMemory") private var useMemory: Bool = RetrievalSettings.useMemory
    
    @AppStorage("defaultSearchProvider") private var defaultSearchProvider: Int = RetrievalSettings.defaultSearchProvider
    
    @State private var tavilyApiKey: String = RetrievalSettings.tavilyApiKey
    @State private var tavilyBackupApiKey: String = RetrievalSettings.tavilyBackupApiKey
    
    @AppStorage("searchResultsMultiplier") private var searchResultsMultiplier: Int = RetrievalSettings.searchResultsMultiplier
    @State private var useWebSearchResultContext: Bool = RetrievalSettings.useWebSearchResultContext
    
    // Graph RAG settings
    @AppStorage("graphRAGEnabled") private var graphRAGEnabled: Bool = RetrievalSettings.graphRAGEnabled
    @AppStorage("graphRAGMaxEntities") private var graphRAGMaxEntities: Int = RetrievalSettings.graphRAGMaxEntities
    @AppStorage("graphRAGCommunityLevels") private var graphRAGCommunityLevels: Int = RetrievalSettings.graphRAGCommunityLevels
    
    var body: some View {
        Form {
            Section {
                useMemoryToggle
                manageMemories
            } header: {
                Text("Memory")
            }
            Section {
                resourcesSearch
            } header: {
                Text("Resources Search")
            }
            Section {
                graphRAGToggle
                if graphRAGEnabled {
                    graphRAGMaxEntitiesSlider
                    graphRAGCommunityLevelsSlider
                }
            } header: {
                Text("Knowledge Graphs")
            } footer: {
                Text("Use knowledge graphs to enhance retrieval by understanding entity relationships and hierarchical themes. Enable this feature per expert in Expert settings.")
                    .font(.caption)
            }
            Section {
                searchProviderPicker
                // If Tavily is selected
                if defaultSearchProvider == 1 {
                    tavilySearch
                }
            } header: {
                Text("Search")
            }
        }
        .formStyle(.grouped)
    }
    
    var useMemoryToggle: some View {
        HStack(
            alignment: .center
        ) {
            VStack(
                alignment: .leading
            ) {
                HStack {
                    Text("Use Memory")
                        .font(.title3)
                        .bold()
                    StatusLabelView.experimental
                }
                Text("Controls whether Sidekick remembers information about you to provide more customized, personal responses in the future.")
                    .font(.caption)
            }
            Spacer()
                .frame(maxWidth: 50)
                .border(Color.blue)
            Toggle("", isOn: $useMemory)
        }
    }
    
    var manageMemories: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text("Memories")
                    .font(.title3)
                    .bold()
                Text("Mange Sidekick's memories.")
                    .font(.caption)
            }
            Spacer()
            Button {
                self.openWindow(id: "memory")
            } label: {
                Text("Manage")
            }
        }
    }
    
    var searchProviderPicker: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Search Provider")
                    .font(.title3)
                    .bold()
                Text("Select the search provider used for web search.")
                    .font(.caption)
            }
            Spacer()
            Picker(
                selection: $defaultSearchProvider.animation(.linear)
            ) {
                Text("DuckDuckGo")
                    .tag(0)
                Text("Tavily")
                    .tag(1)
                Text("Google")
                    .tag(2)
            }
            .pickerStyle(.menu)
        }
    }
    
    var tavilySearch: some View {
        Group {
            tavilyApiKeyEditor
            tavilyBackupApiKeyEditor
        }
        .onAppear {
            self.tavilyApiKey = RetrievalSettings.tavilyApiKey
            self.tavilyBackupApiKey = RetrievalSettings.tavilyBackupApiKey
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
            .foregroundStyle(tavilyApiKey.isEmpty ? .red : .primary)
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
            Picker(selection: $searchResultsMultiplier) {
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
            Toggle("", isOn: $useWebSearchResultContext)
        }
        .onChange(of: useWebSearchResultContext) {
            RetrievalSettings.useWebSearchResultContext = self.useWebSearchResultContext
        }
    }
    
    // MARK: - Graph RAG Settings
    
    var graphRAGToggle: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Enable Knowledge Graphs")
                        .font(.title3)
                        .bold()
                    StatusLabelView.experimental
                }
                Text("Use knowledge graphs to enhance retrieval with entity relationships and hierarchical communities. This provides better context but requires re-indexing.")
                    .font(.caption)
            }
            Spacer()
                .frame(maxWidth: 50)
            Toggle("", isOn: $graphRAGEnabled)
        }
    }
    
    var graphRAGMaxEntitiesSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Maximum Entities")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(graphRAGMaxEntities)")
                    .foregroundColor(.secondary)
            }
            Slider(value: Binding(
                get: { Double(graphRAGMaxEntities) },
                set: { graphRAGMaxEntities = Int($0) }
            ), in: 100...1000, step: 50)
            Text("Maximum number of entities to extract per expert. Higher values provide more detail but slower indexing.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    var graphRAGCommunityLevelsSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Community Levels")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(graphRAGCommunityLevels)")
                    .foregroundColor(.secondary)
            }
            Slider(value: Binding(
                get: { Double(graphRAGCommunityLevels) },
                set: { graphRAGCommunityLevels = Int($0) }
            ), in: 2...5, step: 1)
            Text("Number of hierarchical levels for community detection. More levels capture broader themes.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
}
