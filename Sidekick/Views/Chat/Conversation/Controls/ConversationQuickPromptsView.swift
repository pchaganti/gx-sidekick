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
                    ScrollMask(edge: .leading)
				}
				.overlay(alignment: .trailing) {
                    ScrollMask(edge: .trailing)
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
