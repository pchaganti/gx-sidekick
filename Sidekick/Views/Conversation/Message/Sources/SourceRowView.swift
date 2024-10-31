//
//  SourceRowView.swift
//  Sidekick
//
//  Created by Bean John on 10/31/24.
//

import SwiftUI
import MarkdownUI
import Splash

struct SourceRowView: View {
	
	var source: Source
	var referencedUrl: ReferencedURL? {
		var urlStr: String = source.source
		guard let url: URL = URL(string: urlStr) else {
			return nil
		}
		if url.isWebURL {
			return ReferencedURL(url: url)
		} else {
			urlStr = source.source.removingPercentEncoding ?? source.source
			guard let url: URL = URL(string: urlStr) else {
				return nil
			}
			return ReferencedURL(url: url)
		}
	}
	
	@Environment(\.colorScheme) private var colorScheme
	var shadowColor: SwiftUI.Color {
		return colorScheme == .dark ? .white : .black
	}
	var shadowRadius: CGFloat {
		return colorScheme == .dark ? 2.5 : 1.5
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
		VStack {
			Markdown(source.text)
				.markdownTheme(.gitHub)
				.markdownCodeSyntaxHighlighter(
					.splash(theme: self.theme)
				)
				.textSelection(.enabled)
			Divider()
			HStack {
				Spacer()
				if referencedUrl != nil {
					referencedUrl?.openButton
				} else {
					unknownSource
				}
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 10)
		.background {
			RoundedRectangle(cornerRadius: 10)
				.fill(Color(nsColor: .textBackgroundColor))
				.shadow(
					color: shadowColor,
					radius: shadowRadius
				)
		}
		.padding(.bottom)
	}
	
	var unknownSource: some View {
		Button {
			return
		} label: {
			Text("Unknown Source")
				.font(.body)
				.padding(4)
				.padding(.horizontal, 2)
				.background {
					Capsule()
						.stroke(lineWidth: 1)
				}
		}
		.buttonStyle(.plain)
		.foregroundStyle(Color.secondary)
	}

}
