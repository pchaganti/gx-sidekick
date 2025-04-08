//
//  GeneralSettingsView.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import MarkdownUI
import LaunchAtLogin
import SwiftUI

struct GeneralSettingsView: View {
	
	@AppStorage("username") private var username: String = NSFullUserName()
	
    @AppStorage("useFunctions") private var useFunctions: Bool = Settings.useFunctions
	@AppStorage("playSoundEffects") private var playSoundEffects: Bool = false
	@AppStorage("generateConversationTitles") private var generateConversationTitles: Bool = InferenceSettings.useServer && !InferenceSettings.serverWorkerModelName.isEmpty
	@AppStorage("voiceId") private var voiceId: String = ""
	
	@StateObject private var speechSynthesizer: SpeechSynthesizer = .shared
	
    var body: some View {
		Form {
			Section {
				launchAtLogin
			} header: {
				Text("General")
			}
			Section {
				usernameEditor
				soundEffects
				generateConversationTitlesToggle
				codeInterpreter
				voice
			} header: {
				Text("Chat")
			}
			InlineWritingAssistantSettingsView()
		}
		.formStyle(.grouped)
		.task {
			SpeechSynthesizer.shared.fetchVoices()
		}
    }
	
	var launchAtLogin: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Launch at Login")
					.font(.title3)
					.bold()
				Text("Controls whether Sidekick launches automatically at login.")
					.font(.caption)
			}
			Spacer()
			LaunchAtLogin.Toggle()
				.labelsHidden()
		}
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
		HStack(alignment: .center) {
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
		HStack(alignment: .center) {
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
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Use Functions")
					.font(.title3)
					.bold()
				Text("Encourage models to use functions, which are evaluated to execute actions.")
					.font(.caption)
			}
			Spacer()
            Toggle("", isOn: $useFunctions)
				.toggleStyle(.switch)
		}
	}
	
	var voice: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Voice")
					.font(.title3)
					.bold()
				Text("The voice used to read responses aloud. Download voices in [System Settings -> Accessibility](x-apple.systempreferences:com.apple.preference.universalaccess?SpeakableItems) -> Spoken Content -> System Voice -> Manage Voices.")
					.font(.caption)
			}
			Spacer()
			Picker(
				selection: self.$voiceId
			) {
				ForEach(
					speechSynthesizer.voices,
					id: \.self.identifier
				) { voice in
					Text(voice.prettyName)
						.tag(voice.identifier)
				}
			}
		}
	}
	
}

#Preview {
    GeneralSettingsView()
}
