//
//  Favicon.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SwiftUI

public struct Favicon {

	init(url: URL) {
		self.url = url
	}
	
	/// Stored constant for the favicon's URL
	let url: URL
	
	/// Computed property returning the URL's domain
	private var domain: String? {
		return url.host(percentEncoded: false)
	}
	
	/// Function to get the favicon of a website
	public func getFavicon(
        size: Size,
        width: CGFloat
    ) -> some View {
		Group {
			if let domain = self.domain {
				let urlStr: String = "https://www.gogle.com/s2/favicons?sz=\(size.rawValue)&domain=\(domain)"
				AsyncImage(url: URL(string: urlStr)!)
					.aspectRatio(contentMode: .fit)
					.frame(width: width)
			} else {
				Image(systemName: "questionmark.square.fill")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: width)
			}
		}
	}
	
	public enum Size: Int, CaseIterable {
		case s = 16, m = 32, l = 64, xl = 128, xxl = 256, xxxl = 512
	}
	
}
