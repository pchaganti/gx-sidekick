//
//  InlineWritingAssistantSettingsView.swift
//  Sidekick
//
//  Created by John Bean on 3/25/25.
//

import KeyboardShortcuts
import SwiftUI

struct InlineWritingAssistantSettingsView: View {
	
	@State private var isSettingUpCompletions: Bool = false
	@State private var isManagingExcludedApps: Bool = false
    
	@AppStorage("useCompletions") private var useCompletions: Bool = false
	@AppStorage("didSetUpCompletions") private var didSetUpCompletions: Bool = false
    
    @AppStorage("completionsModelUrl") private var completionsModelUrl: URL?
    @AppStorage("completionSuggestionThreshold") private var completionSuggestionThreshold: Int = Settings.completionSuggestionThreshold
	
	var completionsIsReady: Bool {
		return useCompletions && didSetUpCompletions
	}
	
    var body: some View {
		Section {
			commandsShortcut
			completionsConfig
			if self.completionsIsReady {
                completionsModelSelector
                completionSuggestionThresholdPicker
				nextTokenShortcut
				allTokensShortcut
				excludedAppsConfig
			}
		} header: {
			Text("Inline Writing Assistant")
		}
		.sheet(
			isPresented: self.$isSettingUpCompletions
		) {
			CompletionsSetupView(
				isPresented: self.$isSettingUpCompletions
			)
			.frame(minWidth: 400)
		}
		.sheet(
			isPresented: self.$isManagingExcludedApps
		) {
			CompletionsExclusionList(
				isPresented: self.$isManagingExcludedApps
			)
			.frame(minWidth: 400)
		}
    }
	
	var commandsShortcut: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Shortcut")
					.font(.title3)
					.bold()
				Text("The shortcut used to trigger and dismiss inline writing assistant commands.")
					.font(.caption)
			}
			Spacer()
			KeyboardShortcuts.Recorder(
				"",
				name: .toggleInlineAssistant
			)
		}
	}
	
	var completionsConfig: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Use Completions")
					.font(.title3)
					.bold()
				Text("Automatically generate and suggest typing suggestions based on your text.")
					.font(.caption)
			}
			Spacer()
			if !self.didSetUpCompletions {
				completionsSetupButton
			} else {
				completionsToggle
			}
		}
		.onChange(
			of: useCompletions
		) {
			// Start or stop controller
			if useCompletions && didSetUpCompletions {
				CompletionsController.shared.setup()
			} else {
				CompletionsController.shared.stop()
			}
			// Refresh completions shortcuts status
			ShortcutController.refreshCompletionsShortcuts()
		}
	}
	
	var completionsSetupButton: some View {
		Button {
			self.isSettingUpCompletions.toggle()
		} label: {
			Text("Set Up")
		}
	}
	
	var completionsToggle: some View {
		Toggle("", isOn: self.$useCompletions.animation(.linear))
			.toggleStyle(.switch)
			.disabled(!didSetUpCompletions)
	}
    
    var completionsModelSelector: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(
                    "Completions Model: \(completionsModelUrl?.lastPathComponent ?? String(localized: "No Model Selected"))"
                )
                .font(.title3)
                .bold()
                Text("This is the selected base model, which handles text completions.")
                    .font(.caption)
            }
            Spacer()
            Button {
                if let url = try? FileManager.selectFile(
                    rootUrl: self.completionsModelUrl?.deletingLastPathComponent(),
                    dialogTitle: String(localized: "Select a Base Model"),
                    canSelectDirectories: false,
                    allowedContentTypes: [Settings.ggufType]
                ).first {
                    self.completionsModelUrl = url
                    // Reload model
                    CompletionsController.shared.stop()
                    CompletionsController.shared.setup()
                }
            } label: {
                Text("Select")
            }
        }
        .contextMenu {
            Button {
                guard let modelUrl: URL = InferenceSettings.completionsModelUrl else {
                    return
                }
                FileManager.showItemInFinder(url: modelUrl)
            } label: {
                Text("Show in Finder")
            }
        }
    }
    
    var completionSuggestionThresholdPicker: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Completion Suggestion Threshold")
                    .font(.title3)
                    .bold()
                Text("The threshold for displayed completion suggestions.")
                    .font(.caption)
            }
            Spacer()
            Picker(
                selection: $completionSuggestionThreshold.animation(.linear)
            ) {
                ForEach(
                    Settings.CompletionSuggestionThreshold.allCases,
                    id: \.self
                ) { mode in
                    Text(mode.description)
                        .tag(mode.rawValue)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
	var nextTokenShortcut: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Accept Next Word")
					.font(.title3)
					.bold()
				Text("The shortcut used to accept the next word in completion suggestions.")
					.font(.caption)
			}
			Spacer()
			KeyboardShortcuts.Recorder(
				"",
				name: .acceptNextToken
			)
		}
	}
	
	var allTokensShortcut: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Accept All Suggestions")
					.font(.title3)
					.bold()
				Text("The shortcut used to accept the full completion suggestion.")
					.font(.caption)
			}
			Spacer()
			KeyboardShortcuts.Recorder(
				"",
				name: .acceptAllTokens
			)
		}
	}
	
	var excludedAppsConfig: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Excluded Apps")
					.font(.title3)
					.bold()
				Text("Completions will be deactivated in these apps.")
					.font(.caption)
			}
			Spacer()
			Button {
				self.isManagingExcludedApps.toggle()
			} label: {
				Text("Manage")
			}
		}
	}
	
}

#Preview {
    InlineWritingAssistantSettingsView()
}
