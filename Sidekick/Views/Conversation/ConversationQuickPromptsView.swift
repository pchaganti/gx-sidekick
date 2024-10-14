//
//  ConversationQuickPromptsView.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ConversationQuickPromptsView: View {
	
	@Binding var input: String
	
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack {
				ForEach(QuickPrompt.quickPrompts) { prompt in
					QuickPromptButton(
						input: $input,
						prompt: prompt
					)
				}
			}
			.padding(.horizontal, 10)
			.padding(.top, 200)
		}
		.frame(maxWidth: .infinity)
	}
	
}

struct QuickPromptButton: View {
	
	@Binding var input: String
	
	var prompt: QuickPrompt
	
	var body: some View {
		Button {
			input = prompt.text
		} label: {
			VStack(alignment: .leading) {
				Text(prompt.title)
					.bold()
					.font(.caption2)
					.lineLimit(1)
				Text(prompt.rest)
					.font(.caption2)
					.lineLimit(1)
					.foregroundColor(.secondary)
			}
			.padding(.vertical, 8)
			.padding(.horizontal, 10)
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.buttonStyle(CapsuleButtonStyle())
		.frame(maxWidth: 300)
	}
	
}
