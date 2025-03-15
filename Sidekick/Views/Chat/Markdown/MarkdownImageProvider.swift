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
						.errorMode(.original)
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
		NetworkImage(
			url: url
		) { state in
			switch state {
				case .failure, .empty:
					imageLoadError
				case let .success(image, idealSize):
					image
						.renderingMode(.template)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.padding(.leading, 1)
						.frame(
							idealWidth: idealSize.width * scaleFactor / 2,
							idealHeight: idealSize.height * scaleFactor / 2
						)
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
				let latexImage: Image = await LaTeX(latexStr)
			.blockMode(.alwaysInline)
			.errorMode(.original)
			.padding(.horizontal, 3)
			.offset(y: 2.5)
			.generateImage(
				scale: scaleFactor
			) {
			return latexImage
				.renderingMode(.template)
				.resizable()
		} else {
			return Image(systemName: "questionmark.square.fill")
		}
	}
	
}
