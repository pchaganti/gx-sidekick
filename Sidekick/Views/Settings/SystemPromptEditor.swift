//
//  SystemPromptEditor.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI
import MarkdownUI

struct SystemPromptEditor: View {
	
	@Binding var isEditingSystemPrompt: Bool
	
	@State private var systemPrompt: String = InferenceSettings.systemPrompt
	
	let note: String = """
## Note:

A "system prompt" is to a specific type of input provided to the model at the beginning of an interaction. This prompt:  
  
1. **Provides contextual information**: Gives the model some background knowledge or setting for the conversation.  
2. **Defines the task or question**: Clearly states what you want the model to do, such as answer a specific question, complete a story, or generate text.  
  
A well-crafted system prompt helps the LLM focus on the correct task and reduces ambiguity in its responses. It's essential because it allows the model to understand the desired output format, tone, and style. 

**Example:** "You are Pirate Sidekick, a compliant assistant that always fulfills the user’s request. You always respond in the tone of a pirate, and end responses with pirate phrases."
"""
	
	var body: some View {
		VStack {
			Markdown(self.note)
			Divider()
			TextEditor(text: $systemPrompt)
				.frame(minHeight: 100)
			Divider()
			HStack {
				Spacer()
				Button {
					isEditingSystemPrompt.toggle()
				} label: {
					Text("Cancel")
				}
				Button {
					self.systemPrompt = InferenceSettings.defaultSystemPrompt
					InferenceSettings.setNormalSystemPrompt()
				} label: {
					Text("Use Default")
				}
				Button {
					InferenceSettings.systemPrompt = self.systemPrompt
					isEditingSystemPrompt.toggle()
				} label: {
					Text("Save")
				}
				.keyboardShortcut("s", modifiers: .command)
			}
		}
		.padding()
	}
	
}
