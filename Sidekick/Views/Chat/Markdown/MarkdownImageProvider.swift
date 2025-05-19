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
import WebKit
import WebViewKit

struct MarkdownImageProvider: ImageProvider {
	
	let scaleFactor: CGFloat
    
	public func makeImage(
		url: URL?
	) -> some View {
        return Group {
            if let url: URL = url {
                if url.isWebURL {
                    // If network image
                    self.networkImage(url: url)
                } else if url.isFileURL {
                    // If file image
                    self.fileImage(url: url)
                } else if url.absoluteString.hasPrefix("latex://"),
                          let latexStr = url.withoutSchema.removingPercentEncoding {
                    // If url is LaTeX
                    LaTeX(latexStr)
                        .blockMode(.blockViews)
                        .errorMode(.original)
                        .renderingStyle(.original)
                } else {
                    // Try converting to absolute path
                    let fileUrl: URL = URL(
                        fileURLWithPath: url.posixPath
                    )
                    // If file image
                    self.fileImage(url: fileUrl)
                }
            } else {
                imageLoadError
            }
        }
	}
	
	private func networkImage(
		url: URL
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
    
    private func fileImage(
        url: URL
    ) -> some View {
        var url: URL = url
        // Try to correct url
        if !url.fileExists && url.pathComponents.count <= 2 {
            url = Settings
                .containerUrl
                .appendingPathComponent("Generated Images")
                .appendingPathComponent(url.lastPathComponent)
            print("correctedPath: ", url.posixPath)
        }
        return Group {
            if let nsImage: NSImage = NSImage(
                contentsOf: url
            ) {
                if url.pathExtension == "svg" {
                    ScrollView(
                        .horizontal
                    ) {
                        WebView(
                            url: url
                        ) { view in
                            view.setValue(false, forKeyPath: "drawsBackground")
                        }
                        .frame(
                            width: nsImage.size.width * 0.5,
                            height: nsImage.size.height * 0.5
                        )
                        .allowsHitTesting(false)
                    }
                    .padding(.horizontal, 5)
                } else {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .draggable(
                            nsImage
                        )
                        .padding(.leading, 1)
                }
            } else {
                self.imageLoadError
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
        } else if url.isFileURL {
            // If file image
            return self.fileImage(url: url)
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
        } else {
            // Try converting to absolute path
            let fileUrl: URL = URL(
                fileURLWithPath: url.posixPath
            )
            // If file image
            return self.fileImage(url: fileUrl)
        }
	}

    private func fileImage(
        url: URL
    ) -> Image {
        var url: URL = url
        // Try to correct url
        if !url.fileExists && url.pathComponents.count <= 2 {
            url = Settings
                .containerUrl
                .appendingPathComponent("Generated Images")
                .appendingPathComponent(url.lastPathComponent)
        }
        if let nsImage: NSImage = NSImage(
            contentsOf: url
        ) {
            if url.pathExtension == "svg" {
                let configuration = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
                if let nsImage = NSImage(contentsOf: url)?.withSymbolConfiguration(
                    configuration
                ) {
                    return Image(nsImage: nsImage)
                }
            } else {
                return Image(nsImage: nsImage)
                    .resizable()
            }
        }
        return self.imageLoadError
    }
    
    var imageLoadError: Image {
        Image(systemName: "questionmark.square.fill")
    }
    
}
