//
//  MessageContentView.swift
//  Sidekick
//
//  Created by Bean John on 11/12/24.
//

import LaTeXSwiftUI
import MarkdownUI
import Splash
import SwiftUI
import Shimmer

struct MessageContentView: View {
	
	@Environment(\.colorScheme) private var colorScheme
    
	@State private var cachedMarkdown: AnyView? // Cache rendered markdown view
	
	var text: String
	
	var textLatexProcessed: String {
		return self.text.convertLaTeX()
	}
	
	let imageScaleFactor: CGFloat = 1.0
	
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
		.onChange(of: self.textLatexProcessed) { _, newText in
			self.updateCachedMarkdown(newText) // Only redraw when text changes
		}
		.onAppear {
			if self.cachedMarkdown == nil {
				self.updateCachedMarkdown(
					self.textLatexProcessed
				) // Cache on appear
			}
		}
	}
	
	@ViewBuilder
	var content: some View {
		if let cached = cachedMarkdown {
			cached // Used cached view if available
		} else {
			self.markdownView(
				self.textLatexProcessed
			)
		}
	}
	
	@ViewBuilder
	private func markdownView(_ text: String) -> some View {
		Markdown(MarkdownContent(text))
			.markdownTheme(.gitHub)
			.markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
			.markdownImageProvider(
				MarkdownImageProvider(scaleFactor: imageScaleFactor)
			)
			.markdownInlineImageProvider(
				MarkdownInlineImageProvider(
					scaleFactor: imageScaleFactor
				)
			)
			.textSelection(.enabled)
	}
	
	private func updateCachedMarkdown(_ newText: String) {
		self.cachedMarkdown = AnyView(
			Markdown(MarkdownContent(newText))
				.markdownTheme(.gitHub)
				.markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
				.markdownImageProvider(
					MarkdownImageProvider(
						scaleFactor: imageScaleFactor
					)
				)
				.markdownInlineImageProvider(
					MarkdownInlineImageProvider(
						scaleFactor: imageScaleFactor
					)
				)
				.textSelection(.enabled)
		)
	}
	
}
