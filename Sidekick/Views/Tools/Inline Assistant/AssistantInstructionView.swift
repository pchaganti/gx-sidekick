//
//  AssistantInstructionView.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import MarkdownUI
import SwiftUI

struct AssistantInstructionView: View {
	
	var instruction: String {
		return [
			String(localized: "Sidekick's Inline Writing Assistant is enabled by default."),
			commandsInstructions,
			completionsInstructions,
			changeShortcutInstructions
		].joined(separator: "\n\n")
	}
	
	let commandsInstructions: String = String(localized: """
Use the default keyboard shortcut `Command 􀆔 + Control 􀆍 + I` to toggle commands.
""")
	
	let completionsInstructions: String = String(localized: """
Use the default keyboard shortcut `Tab` to accept suggestions for the next word, or `Shift + Tab` to accept all suggested words.
""")
	
	let changeShortcutInstructions: String = String(localized: "Default shortcuts can be modified in `Settings -> General`.")
	
	@Binding var showAssistantInstructionSheet: Bool
	
    var body: some View {
		VStack(
			spacing: 7
		) {
			HStack {
				ExitButton {
					self.showAssistantInstructionSheet.toggle()
				}
				Spacer()
			}
			Markdown(MarkdownContent(self.instruction))
		}
		.padding(8)
		.padding(.bottom, 10)
    }
	
}
