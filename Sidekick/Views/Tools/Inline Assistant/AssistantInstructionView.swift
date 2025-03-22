//
//  AssistantInstructionView.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import KeyboardShortcuts
import MarkdownUI
import SwiftUI

struct AssistantInstructionView: View {
	
	let instruction: String = String(localized: """
Sidekick's Inline Assistant is enabled by default.

Use the default keyboard shortcut `Command 􀆔 + Control 􀆍 + I` to toggle the assistant. You can change this shortcut in `Settings -> General`.
""")
	
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
