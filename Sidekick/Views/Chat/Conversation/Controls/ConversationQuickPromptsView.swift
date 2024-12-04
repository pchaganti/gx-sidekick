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
		ScrollView(
			.horizontal, showsIndicators: false
		) {
			prompts
		}
		.mask {
			Rectangle()
				.overlay(alignment: .leading) {
					ScrollMask(isLeading: true)
				}
				.overlay(alignment: .trailing) {
					ScrollMask(isLeading: false)
				}
		}
	}
	
	var prompts: some View {
		HStack {
			ForEach(QuickPrompt.quickPrompts) { prompt in
				QuickPromptButton(
					input: $input,
					prompt: prompt
				)
			}
		}
		.padding(.horizontal, 20)
	}
	
}

struct QuickPromptButton: View {
	
	@Binding var input: String
	
	var prompt: QuickPrompt
	
	var body: some View {
		Button {
			withAnimation(.linear) {
				self.input = self.prompt.text
			}
		} label: {
			prompt.label
				.padding(.vertical, 8)
				.padding(.horizontal, 10)
				.frame(
					maxWidth: .infinity,
					alignment: .leading
				)
				.frame(minHeight: 35)
		}
		.buttonStyle(CapsuleButtonStyle())
		.frame(maxWidth: 300)
	}
	
}
