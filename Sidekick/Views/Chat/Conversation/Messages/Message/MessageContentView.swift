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
	
	@State private var cachedMarkdown: AnyView? // Cache rendered markdown view
	
	var text: String
	
	private var chunks: [Message.Chunk] {
		self.text.replacingOccurrences(of: "\\(", with: "")
			.replacingOccurrences(of: "\\)", with: "")
			.splitByLatex()
			.map { Message.Chunk(content: $0.string, isLatex: $0.isLatex) }
	}
	
	private var hasLatex: Bool {
		self.chunks.contains(where: \.isLatex)
	}
	
	private var theme: Splash.Theme {
		switch self.colorScheme {
			case .dark: return .wwdc17(withFont: .init(size: 16))
			default: return .sunset(withFont: .init(size: 16))
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			self.content
		}
		.if(self.hasLatex) { view in
			view.overlay(alignment: .bottomTrailing) {
				ToggleLaTeXButton(renderLatex: self.$renderLatex)
			}
		}
		.onChange(of: self.text) { _, newText in
			self.updateCachedMarkdown(newText) // Only redraw when text changes
		}
		.onAppear {
			if self.cachedMarkdown == nil {
				self.updateCachedMarkdown(self.text) // Cache on appear
			}
		}
	}
	
	@ViewBuilder
	var content: some View {
		if self.renderLatex && self.hasLatex {
			ForEach(self.chunks) { chunk in
				if chunk.isLatex {
					MathView(equation: chunk.content, font: .latinModernFont)
						.frame(minWidth: 100, minHeight: NSFont.systemFontSize * 3)
				} else {
					self.markdownView(chunk.content)
				}
			}
		} else {
			if let cached = cachedMarkdown {
				cached // Used cached view if available
			} else {
				self.markdownView(self.text) // Fall back on live view
			}
		}
	}
	
	@ViewBuilder
	private func markdownView(_ text: String) -> some View {
		Markdown(text)
			.markdownTheme(.gitHub)
			.markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
			.textSelection(.enabled)
	}
	
	private func updateCachedMarkdown(_ newText: String) {
		if self.renderLatex && self.hasLatex {
			self.cachedMarkdown = nil // If there is LaTeX, only cache part of the view
		} else {
			self.cachedMarkdown = AnyView(
				Markdown(newText)
					.markdownTheme(.gitHub)
					.markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
					.textSelection(.enabled)
			)
		}
	}
}
