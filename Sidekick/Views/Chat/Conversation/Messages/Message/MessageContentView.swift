//
//  MessageContentView.swift
//  Sidekick
//
//  Created by Bean John on 11/12/24.
//

import MarkdownUI
import Splash
import SwiftUI

struct MessageContentView: View {
	
	@Environment(\.colorScheme) private var colorScheme
	
	@State private var renderLatex: Bool = true
	
	var message: Message
	var viewReferenceTip: ViewReferenceTip = .init()
	
	private var theme: Splash.Theme {
		// NOTE: We are ignoring the Splash theme font
		switch colorScheme {
			case ColorScheme.dark:
				return .wwdc17(withFont: .init(size: 16))
			default:
				return .sunset(withFont: .init(size: 16))
		}
	}
	
	private var messageChunks: [(string: String, isLatex: Bool)] {
		return message.text.splitByLatex()
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			content
				.textSelection(.enabled)
			if !message.referencedURLs.isEmpty {
				messageReferences
			}
		}
		.if(self.message.hasLatex) { view in
			view
				.overlay(alignment: .bottomTrailing) {
					ToggleLaTeXButton(renderLatex: $renderLatex)
				}
		}
	}
	
	var content: some View {
		Group {
			if self.renderLatex {
				contentWithLaTeX
			} else {
				Markdown(message.text)
					.markdownTheme(.gitHub)
					.markdownCodeSyntaxHighlighter(
						.splash(theme: self.theme)
					)
			}
		}
	}
	
	var contentWithLaTeX: some View {
		ForEach(self.message.chunks) { chunk in
			Group {
				if chunk.isLatex {
					MathView(
						equation: chunk.content,
						font: .latinModernFont
					)
					.frame(
						minWidth: 100,
						minHeight: (NSFont.systemFontSize + 1.0) * 3.0
					)
				} else {
					Markdown(chunk.content)
						.markdownTheme(.gitHub)
						.markdownCodeSyntaxHighlighter(
							.splash(theme: self.theme)
						)
				}
			}
		}
	}
	
	var messageReferences: some View {
		VStack(
			alignment: .leading
		) {
			Text("References:")
				.bold()
				.font(.body)
				.foregroundStyle(Color.secondary)
			ForEach(
				message.referencedURLs.indices,
				id: \.self
			) { index in
				message.referencedURLs[index].openButton
					.if(index == 0) { view in
						view.popoverTip(viewReferenceTip)
					}
			}
		}
		.padding(.top, 8)
		.onAppear {
			ViewReferenceTip.hasReference = true
		}
	}
	
}
