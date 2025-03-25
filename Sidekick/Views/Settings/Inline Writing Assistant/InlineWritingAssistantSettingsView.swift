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
	
	@AppStorage("useCompletions") private var useCompletions: Bool = false
	@AppStorage("didSetUpCompletions") private var didSetUpCompletions: Bool = false
	
	var completionsIsReady: Bool {
		return useCompletions && didSetUpCompletions
	}
	
    var body: some View {
		Section {
			commandsShortcut
			completionsConfig
			if self.completionsIsReady {
				nextTokenShortcut
				allTokensShortcut
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
	
}

#Preview {
    InlineWritingAssistantSettingsView()
}
