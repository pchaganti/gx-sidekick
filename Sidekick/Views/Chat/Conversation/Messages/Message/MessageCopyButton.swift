//
//  MessageCopyButton.swift
//  Sidekick
//
//  Created by John Bean on 3/18/25.
//

import SwiftUI

struct MessageCopyButton: View {
	
	var message: Message
	
	private var isGenerating: Bool {
		return !message.outputEnded && message.getSender() == .assistant
	}
	
    var body: some View {
		Group {
			if message.hasReasoning {
				menu
			} else {
				copyButton
					.labelStyle(.iconOnly)
			}
		}
		.disabled(isGenerating)
    }
	
	var menu: some View {
		Menu {
			copyMenu
		} label: {
			Image(systemName: "square.on.square")
				.foregroundStyle(.secondary)
		}
		.menuStyle(.circle)
		.padding(0)
		.padding(.vertical, 2)
	}
	
	var copyMenu: some View {
		Group {
			// If message was produced by a reasoning model
			if let reasoningText = self.message.reasoningText {
				Button {
					reasoningText.copyWithFormatting()
				} label: {
					Text("Copy Reasoning Process")
				}
				Button {
					self.message.responseText.copyWithFormatting()
				} label: {
					Text("Copy Answer")
				}
			}
		}
	}
	
	var copyButton: some View {
		Button {
			self.message.text.copyWithFormatting()
		} label: {
			Label("Copy to Clipboard", systemImage: "square.on.square")
				.labelStyle(.iconOnly)
				.imageScale(.medium)
				.background(.clear)
				.imageScale(.small)
				.padding(.leading, 1)
				.padding(.horizontal, 3)
				.frame(width: 15, height: 15)
				.scaleEffect(CGSize(width: 0.96, height: 0.96))
				.foregroundStyle(.secondary)
				.scaleEffect(x: -1)
		}
		.buttonStyle(.plain)
	}
	
}
