//
//  QuickPromptButton.swift
//  Sidekick
//
//  Created by John Bean on 3/15/25.
//

import SwiftUI

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
