//
//  TemporaryResourceView.swift
//  Sidekick
//
//  Created by Bean John on 10/24/24.
//

import SwiftUI

struct TemporaryResourceView: View {
	
	@Binding var tempResource: TemporaryResource
	
	@State private var isHovering: Bool = false
	
    var body: some View {
		Button {
			self.open()
		} label: {
			HStack {
				QLThumbnail(
					url: tempResource.url,
					resolution: CGSize(width: 512, height: 512),
					scale: 0.5,
					representationTypes: .thumbnail,
					tapToPreview: true,
					resizable: false
				)
			}
		}
		.buttonStyle(CapsuleButtonStyle())
		.frame(maxWidth: 300)
		.onHover { hovering in
			self.isHovering = hovering
		}
    }
	
	private func open() {
		NSWorkspace.shared.open(tempResource.url)
	}
	
}
