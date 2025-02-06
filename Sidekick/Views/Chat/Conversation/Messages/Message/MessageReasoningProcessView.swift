//
//  MessageReasoningProcessView.swift
//  Sidekick
//
//  Created by John Bean on 2/6/25.
//

import SwiftUI

struct MessageReasoningProcessView: View {
	
	@State var showReasoning: Bool = true
	
	var message: Message
	
    var body: some View {
		VStack(
			alignment: .leading,
			spacing: 10
		) {
			toggleReasoningButton
			// Show reasoning if needed
			if self.showReasoning {
				MessageContentView(text: self.message.reasoningText!)
					.italic()
					.padding(.horizontal, 10)
					.padding(.bottom, 10)
			}
		}
		.background {
			RoundedRectangle(cornerRadius: 7)
				.fill(Color.gray.opacity(0.1))
		}
	}
	
	var toggleReasoningButton: some View {
		Button {
			withAnimation(.linear) {
				self.showReasoning.toggle()
			}
		} label: {
			RoundedRectangle(cornerRadius: 7)
				.fill(Color.purple.opacity(0.1))
				.overlay {
					HStack {
						Label("Reasoning Process", systemImage: "brain.fill")
						Spacer()
						Image(systemName: "chevron.up")
							.rotationEffect(
								self.showReasoning ? .zero : .degrees(180)
							)
					}
					.foregroundStyle(Color.purple)
					.padding(.horizontal, 5)
				}
				.frame(minHeight: 32)
		}
		.buttonStyle(.plain)
	}
	
}
