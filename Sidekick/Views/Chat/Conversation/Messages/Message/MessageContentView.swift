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
	
	var text: String
	
	/// An array of type ``Chunk`` indicating chunks in the text
	private var chunks: [Message.Chunk] {
		return self
			.text
			.replacingOccurrences(
				of: "\\(",
				with: ""
			)
			.replacingOccurrences(
				of: "\\)",
				with: ""
			)
			.splitByLatex()
			.map { chunk in
				return Message.Chunk(
					content: chunk.string,
					isLatex: chunk.isLatex
				)
			}
	}
	
	/// A `Bool` indicating whether the text contains LaTeX
	private var hasLatex: Bool {
		return self.chunks.contains(where: \.isLatex)
	}
	
	private var theme: Splash.Theme {
		// NOTE: We are ignoring the Splash theme font
		switch colorScheme {
			case ColorScheme.dark:
				return .wwdc17(withFont: .init(size: 16))
			default:
				return .sunset(withFont: .init(size: 16))
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			content
		}
		.if(self.hasLatex) { view in
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
				Markdown(self.text)
					.markdownTheme(.gitHub)
					.markdownCodeSyntaxHighlighter(
						.splash(theme: self.theme)
					)
			}
		}
		.textSelection(.enabled)
	}
	
	var contentWithLaTeX: some View {
		ForEach(self.chunks) { chunk in
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

}
