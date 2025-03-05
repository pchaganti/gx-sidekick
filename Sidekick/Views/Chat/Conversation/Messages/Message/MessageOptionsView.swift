//
//  MessageOptionsView.swift
//  Sidekick
//
//  Created by Bean John on 11/12/24.
//

import MarkdownUI
import Splash
import SwiftUI

struct MessageOptionsView: View {
	
	@Environment(\.colorScheme) private var colorScheme
	
	@State private var showNerdInfo: Bool = false
	@State private var showInterpreterCode: Bool = false
	@Binding var isEditing: Bool
	
	var message: Message
	var canEdit: Bool
	
	var interpreterCodeAction: String {
		return showNerdInfo ? String(localized: "Hide Code Used") : String(localized: "Show Code Used")
	}
	
	private var theme: Splash.Theme {
		switch self.colorScheme {
			case .dark: return .wwdc17(withFont: .init(size: 16))
			default: return .sunset(withFont: .init(size: 16))
		}
	}
	
	private var isGenerating: Bool {
		return !message.outputEnded && message.getSender() == .assistant
	}
	
	private var nerdInfo: String {
		var tokensPerSecondStr: String = "Unknown"
		if let tokensPerSecond = message.tokensPerSecond {
			tokensPerSecondStr = "\(round(tokensPerSecond * 10) / 10)"
		}
		let infoDescription: String.LocalizationValue = """
Model: \(message.model)
Tokens per second: \(tokensPerSecondStr)
"""
		return String(localized: infoDescription)
	}
	
    var body: some View {
		Menu {
			optionsMenu
		} label: {
			Image(systemName: "ellipsis.circle")
				.imageScale(.medium)
				.background(.clear)
				.imageScale(.small)
				.padding(.leading, 1)
				.padding(.horizontal, 3)
				.frame(width: 15, height: 15)
				.scaleEffect(CGSize(width: 0.96, height: 0.96))
				.background(.primary.opacity(0.00001)) // Needs to be clickable
		}
		.menuStyle(.circle)
		.popover(isPresented: $showNerdInfo) {
			Text(nerdInfo)
				.padding(12)
				.font(.caption)
				.textSelection(.enabled)
		}
		.popover(isPresented: $showInterpreterCode) {
			codeView
		}
		.disabled(isGenerating)
		.padding(0)
		.padding(.vertical, 2)
    }
	
	var optionsMenu: some View {
		Group {
			copyButton
			// Edit button
			if self.canEdit && !self.isEditing {
				Button {
					if self.canEdit {
						withAnimation(
							.linear(duration: 0.5)
						) {
							self.isEditing.toggle()
						}
					}
				} label: {
					Text("Edit")
				}
			}
			// Show code used in code interpreter
			if message.usedCodeInterpreter ?? false && message.jsCode != nil {
				Button {
					showInterpreterCode.toggle()
				} label: {
					Text(interpreterCodeAction)
				}
			}
			// Show info for bots
			if message.getSender() == .assistant {
				Button {
					showNerdInfo.toggle()
				} label: {
					Text("Stats for Nerds")
				}
			}
		}
	}
	
	var copyButton: some View {
		Group {
			// If message was produced by a reasoning model
			if let reasoningText = self.message.reasoningText {
				Button {
					reasoningText.copy()
				} label: {
					Text("Copy Reasoning Process")
				}
				Button {
					self.message.responseText.copy()
				} label: {
					Text("Copy Answer")
				}
			} else {
				// Else, only allow copying of answer
				Button {
					self.message.text.copy()
				} label: {
					Text("Copy to Clipboard")
				}
			}
		}
	}
	
	var codeView: some View {
		Group {
			if let jsCode = self.message.jsCode {
				ScrollView {
					Markdown {
						CodeBlock(
							language: "JavaScript",
							content: jsCode
						)
					}
					.markdownTheme(.gitHub)
					.markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
					.padding(12)
					.textSelection(.enabled)
				}
			} else {
				EmptyView()
			}
		}
	}
	
}
