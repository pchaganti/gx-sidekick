//
//  SourcesView.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import MarkdownUI
import Splash
import SwiftUI

struct SourcesView: View {
	
	@Binding var isShowingSources: Bool
	var sources: Sources
	
	@State private var query: String = ""
	
	var filteredSources: [Source] {
		if query.isEmpty {
			return sources.sources.sorted(by: \.text)
		}
		let filteredSources: [Source] = sources.sources.filter { source in
			return source.text.lowercased().contains(query.lowercased())
		}
		return filteredSources.sorted(by: \.text)
	}
	
    var body: some View {
		VStack(
			alignment: .leading
		) {
			HStack {
				Text("Sources")
					.font(.title2)
					.bold()
				Spacer()
				TextField(text: $query, label: {
					Label("Search", systemImage: "magnifyingglass")
						.labelStyle(.titleAndIcon)
				})
				.textFieldStyle(.roundedBorder)
				.frame(maxWidth: 180)
				ExitButton {
					isShowingSources.toggle()
				}
			}
			.padding([.top, .trailing])
			Divider()
			List(
				filteredSources
			) { source in
				SourceRowView(source: source)
					.listRowSeparator(.hidden)
			}
		}
		.padding(.leading)
    }
}

struct SourceRowView: View {
	
	var source: Source
	var referencedUrl: ReferencedURL? {
		guard let url: URL = URL(string: source.source) else { return nil }
		return ReferencedURL(url: url)
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
