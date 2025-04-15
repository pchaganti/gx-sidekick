//
//  MarkdownImageProvider.swift
//  Sidekick
//
//  Created by John Bean on 3/15/25.
//

import Foundation
import LaTeXSwiftUI
import MarkdownUI
import NetworkImage
import SwiftUI

struct MarkdownImageProvider: ImageProvider {
	
	let scaleFactor: CGFloat
	
	public func makeImage(
		url: URL?
	) -> some View {
		Group {
			if let url: URL = url {
				if url.isWebURL {
					// If network image
					self.networkImage(url: url)
				} else if url.absoluteString.hasPrefix("latex://"),
						  let latexStr = url.withoutSchema.removingPercentEncoding {
					// If url is LaTeX
					LaTeX(latexStr)
						.blockMode(.blockViews)
						.errorMode(.original)
						.renderingStyle(.original)
				} else {
					imageLoadError
				}
			} else {
				imageLoadError
			}
		}
	}
	
	private func networkImage(
		url: URL?
	) -> some View {
		AsyncImage(
			url: url
		) { phase in
			switch phase {
				case .empty, .failure:
					imageLoadError
				case .success(let image):
					image
						.renderingMode(.template)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.draggable(
							image
						)
						.padding(.leading, 1)
				@unknown default:
					imageLoadError
			}
		}
	}
	
	var imageLoadError: some View {
		Label(
			"Error loading image",
			systemImage: "exclamationmark.square.fill"
		)
		.foregroundColor(.red)
	}
	
}

struct MarkdownInlineImageProvider: InlineImageProvider {
	
	let scaleFactor: CGFloat
	
    @MainActor
	public func image(
		with url: URL,
		label: String
	) async throws -> Image {
		if url.isWebURL {
			let image = try await Image(
				DefaultNetworkImageLoader.shared.image(from: url),
				scale: 2 / scaleFactor,
				label: Text(label)
			)
			return image.renderingMode(.template).resizable()
		} else if url.absoluteString.hasPrefix("latex://"),
			let latexStr = url.withoutSchema.removingPercentEncoding,
				let latexImage: Image = LaTeX(latexStr)
					.blockMode(.alwaysInline)
					.errorMode(.original)
					.padding(.horizontal, 3)
					.offset(y: 2.75)
					.generateImage(
						scale: scaleFactor
					) {
			return latexImage
				.renderingMode(.template)
				.resizable()
		}
		return Image(systemName: "questionmark.square.fill")
	}
	
}
