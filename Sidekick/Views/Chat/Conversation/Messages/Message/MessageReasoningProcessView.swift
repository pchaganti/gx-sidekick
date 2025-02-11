//
//  MessageReasoningProcessView.swift
//  Sidekick
//
//  Created by John Bean on 2/6/25.
//

import SwiftUI

struct MessageReasoningProcessView: View {
	
	init(message: Message) {
		let outputDidEnd: Bool = message.outputEnded
		let reasoningOutputDidEnd: Bool = message.reasoningText != nil && !message.responseText.isEmpty
		self._showReasoning = State(
			initialValue: !(outputDidEnd || reasoningOutputDidEnd)
		)
		self.message = message
	}
	
	@State var showReasoning: Bool
	
	var message: Message
	
    var body: some View {
		VStack(
			alignment: .leading,
			spacing: 0
		) {
			toggleReasoningButton
			// Show reasoning if needed
			if self.showReasoning {
				MessageContentView(text: self.message.reasoningText!)
					.italic()
					.padding([.horizontal, .vertical], 10)
					.padding(.leading, 10)
					.overlay(alignment: .leading) {
						UnevenRoundedRectangle(
							topLeadingRadius: 0,
							bottomLeadingRadius: 7,
							bottomTrailingRadius: 0,
							topTrailingRadius: 0
						)
						.fill(Color.purple.opacity(0.2))
						.frame(width: 7)
						.frame(maxHeight: .infinity)
					}
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
			UnevenRoundedRectangle(
				topLeadingRadius: 7,
				bottomLeadingRadius: self.showReasoning ? 0 : 7,
				bottomTrailingRadius: 7,
				topTrailingRadius: 7
			)
			.fill(Color.purple.opacity(0.2))
			.overlay {
				HStack {
					Label("Reasoning Process", systemImage: "brain.fill")
						.fontWeight(.semibold)
					Spacer()
					Image(systemName: "chevron.up")
						.fontWeight(.semibold)
						.rotationEffect(
							self.showReasoning ? .zero : .degrees(180)
						)
				}
				.foregroundStyle(Color.purple)
				.padding(.horizontal, 7)
			}
			.frame(height: 33)
		}
		.buttonStyle(.plain)
	}

}
