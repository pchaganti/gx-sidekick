//
//  ThumbnailView.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SwiftUI

public struct ThumbnailView: View {
	
	init(
		url: URL,
		thumbnailWidth: CGFloat = 10
	) {
		self.url = url
		self.thumbnailWidth = thumbnailWidth
	}
	
	public var url: URL
	public var thumbnailWidth: CGFloat
	@State private var thumbnail: CGImage?
	
	public var body: some View {
		Group {
			if self.url.isWebURL {
				websiteThumbnail
			} else {
				fileThumbnail
			}
		}
	}
	
	private var websiteThumbnail: some View {
		Group {
			Favicon(url: self.url).getFavicon(
				size: .m,
				width: thumbnailWidth
			)
		}
	}
	
	private var fileThumbnail: some View {
		Group {
			if let thumbnail = thumbnail {
				Image(thumbnail, scale: 1.0, label: Text(""))
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: thumbnailWidth)
			} else {
				Image(systemName: "questionmark.square")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: thumbnailWidth)
			}
		}
		.task {
			if FileManager.default.isReadableFile(atPath: url.posixPath) {
				await self.url.thumbnail(
					size: CGSize(width: 512, height: 512),
					scale: 1
				) { cgImage in
					self.thumbnail = cgImage
				}
			}
		}
	}
	
}
