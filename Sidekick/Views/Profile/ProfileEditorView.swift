//
//  ProfileEditorView.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI
import SymbolPicker

struct ProfileEditorView: View {
	
	@EnvironmentObject private var profileManager: ProfileManager
	
	@Binding var profile: Profile
	
	@State private var isSelectingSymbol: Bool = false
	@State private var systemPrompt: String = ""
	
	@Binding var isEditing: Bool
	
    var body: some View {
		VStack {
			Group {
				form
			}
			Divider()
			HStack {
				Spacer()
				Button("Done") {
					isEditing.toggle()
				}
				.keyboardShortcut(.defaultAction)
			}
			.padding([.trailing, .bottom])
		}
		.onAppear {
			systemPrompt = profile.systemPrompt ?? InferenceSettings.systemPrompt
		}
		.sheet(isPresented: $isSelectingSymbol) {
			SymbolPicker(
				symbol: $profile.symbolName
			)
			.frame(maxWidth: 600, maxHeight: 800)
		}
    }
	
	var form: some View {
		Form {
			Section {
				name
			} header: {
				Text("Name")
			}
			Section {
				icon
			} header: {
				Text("Icon")
			}
			ResourceSectionView(profile: $profile)
			Section {
				systemPromptEditor
			} header: {
				Text("System Prompt")
			}
		}
		.formStyle(.grouped)
	}
	
	var name: some View {
		Group {
			Group {
				HStack {
					VStack(alignment: .leading) {
						Text("Name")
							.font(.title3)
							.bold()
						Text("This profile's name")
							.font(.caption)
					}
					Spacer()
					TextField("", text: $profile.name)
						.textFieldStyle(.plain)
				}
			}
			.padding(.horizontal, 5)
		}
	}
		
	var icon: some View {
		Group {
			VStack {
				HStack {
					VStack(alignment: .leading) {
						Text("Icon:")
							.font(.title3)
							.bold()
						Text("This profile's icon")
							.font(.caption)
					}
					Spacer()
					profile.label
				}
				symbol
				HStack {
					VStack(alignment: .leading) {
						Text("Color:")
							.font(.title3)
							.bold()
						Text("This icon's color")
							.font(.caption)
					}
					Spacer()
					ColorPicker(
						"",
						selection: $profile.color,
						supportsOpacity: false
					)
				}
			}
			.padding(.horizontal, 5)
		}
	}
	
	var symbol: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Symbol:")
					.font(.title3)
					.bold()
				Text("This icon's symbol")
					.font(.caption)
			}
			Spacer()
			Button {
				isSelectingSymbol.toggle()
			} label: {
				Label("Change", systemImage: profile.symbolName)
					.labelStyle(.titleAndIcon)
			}
		}
	}
	
	var systemPromptEditor: some View {
		Group {
			Group {
				HStack(alignment: .top) {
					VStack(alignment: .leading) {
						Text("System Prompt")
							.font(.title3)
							.bold()
						Text("This profile's system prompt")
							.font(.caption)
						Button("Use Default") {
							systemPrompt = InferenceSettings.systemPrompt
						}
					}
					Spacer()
					TextEditor(text: $systemPrompt)
						.font(.title2)
						.onChange(
							of: systemPrompt
						) {
							saveSystemPrompt()
						}
				}
			}
			.padding(.horizontal, 5)
		}
	}
	
	private func saveSystemPrompt() {
		// Save system prompt changes
		if !systemPrompt.isEmpty {
			if systemPrompt == InferenceSettings.systemPrompt {
				profile.systemPrompt = nil
				return
			}
			profile.systemPrompt = systemPrompt
		}
	}
	
}

//#Preview {
//    ProfileEditorView()
//}
