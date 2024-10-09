//
//  MessageView.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import MarkdownUI
import Splash
import SwiftUI

struct MessageView: View {
	
	@Environment(\.colorScheme) private var colorScheme
	
	@State private var showNerdInfo: Bool = false
	
	var message: Message
	
	private var theme: Splash.Theme {
		// NOTE: We are ignoring the Splash theme font
		switch colorScheme {
			case ColorScheme.dark:
				return .wwdc17(withFont: .init(size: 16))
			default:
				return .sunset(withFont: .init(size: 16))
		}
	}
	
	private var isOptionsDisabled: Bool {
		return !message.outputEnded && message.getSender() == .system
	}
	
	private var nerdInfo: String {
		var tokensPerSecondStr: String = "Unknown"
		if let tokensPerSecond = message.tokensPerSecond {
			tokensPerSecondStr = "\(round(tokensPerSecond * 10) / 10)"
		}
		return """
Model: \(message.model)
Tokens per second: \(tokensPerSecondStr)
"""
	}
	
	private var timeDescription: String {
		return message.startTime.formatted(
			date: .abbreviated,
			time: .shortened
		)
	}
	
    var body: some View {
		HStack(
			alignment: .top,
			spacing: 0
		) {
			message.icon
				.padding(.trailing, 10)
			VStack(
				alignment: .leading,
				spacing: 8
			) {
				HStack {
					Text(timeDescription)
						.foregroundStyle(.secondary)
					options
				}
				content
			}
		}
    }
	
	var content: some View {
		Markdown(message.text)
			.markdownTheme(.gitHub)
			.markdownCodeSyntaxHighlighter(
				.splash(theme: self.theme)
			)
			.contextMenu {
				Button {
					self.message.text.copy()
				} label: {
					Text("Copy All")
				}
			}
	}
	
	var options: some View {
		Menu(content: {
			optionsMenu
		}, label: {
			Image(systemName: "ellipsis.circle")
				.imageScale(.medium)
				.background(.clear)
				.imageScale(.small)
				.padding(.leading, 1)
				.padding(.horizontal, 3)
				.frame(width: 15, height: 15)
				.scaleEffect(CGSize(width: 0.96, height: 0.96))
				.background(.primary.opacity(0.00001)) // Needs to be clickable
		})
		.menuStyle(.circle)
		.popover(isPresented: $showNerdInfo) {
			Text(nerdInfo)
				.padding(12)
				.font(.caption)
				.textSelection(.enabled)
		}
		.disabled(isOptionsDisabled)
		.padding(0)
		.padding(.vertical, 2)
	}
	
	var optionsMenu: some View {
		Group {
			Button("Copy to Clipboard") {
				message.text.copy()
			}
			// Show info for bots
			if message.getSender() == .system {
				Button("Stats for Nerds") {
					showNerdInfo.toggle()
				}
			}
		}
	}
	
}

//#Preview {
//	MessageView()
//}
