//
//  GeneralSettingsView.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI
import KeyboardShortcuts

struct GeneralSettingsView: View {
	
	@AppStorage("username") private var username: String = NSFullUserName()
	@AppStorage("useCodeInterpreter") private var useCodeInterpreter: Bool = true
	@AppStorage("playSoundEffects") private var playSoundEffects: Bool = false
	@AppStorage("generateConversationTitles") private var generateConversationTitles: Bool = true
	
    var body: some View {
		Form {
			Section {
				usernameEditor
			} header: {
				Text("Username")
			}
			Section {
				soundEffects
				generateConversationTitlesToggle
				codeInterpreter
			} header: {
				Text("Chat")
			}
			Section {
				inlineAssistantShortcut
			} header: {
				Text("Inline Assistant")
			}
		}
		.formStyle(.grouped)
    }
	
	var usernameEditor: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Username")
					.font(.title3)
					.bold()
				Text("Sidekick will refer to you by this username.")
					.font(.caption)
			}
			Spacer()
			TextField("", text: $username)
				.textFieldStyle(.roundedBorder)
				.frame(width: 300)
		}
	}
	
	var soundEffects: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Play Sound Effects")
					.font(.title3)
					.bold()
				Text("Play sound effects when text generation begins and ends.")
					.font(.caption)
			}
			Spacer()
			Toggle("", isOn: $playSoundEffects)
				.toggleStyle(.switch)
		}
	}
	
	var generateConversationTitlesToggle: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Generate Conversation Titles")
					.font(.title3)
					.bold()
				Text("Automatically generate conversation titles based on the first message in each conversation.")
					.font(.caption)
			}
			Spacer()
			Toggle("", isOn: $generateConversationTitles)
				.toggleStyle(.switch)
		}
	}
	
	var codeInterpreter: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Use Code Interpreter")
					.font(.title3)
					.bold()
				Text("Encourage models to generate code, which is evaluated to produce a more accurate answer.")
					.font(.caption)
			}
			Spacer()
			Toggle("", isOn: $useCodeInterpreter)
				.toggleStyle(.switch)
		}
	}
	
	var inlineAssistantShortcut: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Shortcut")
					.font(.title3)
					.bold()
				Text("The shortcut used to trigger and dismiss the inline writing assistant.")
					.font(.caption)
			}
			Spacer()
			KeyboardShortcuts.Recorder(
				"",
				name: .toggleInlineAssistant
			)
		}
	}
	
}

#Preview {
    GeneralSettingsView()
}
