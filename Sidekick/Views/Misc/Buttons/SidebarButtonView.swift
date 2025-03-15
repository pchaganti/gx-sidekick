//
//  SidebarButtonView.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI

struct SidebarButtonView: View {
	
	@State private var isHovering: Bool = false
	
	var title: String
	var systemImage: String
	
	var action: () -> Void
	
	var buttonOpacity: Double {
		return self.isHovering ? 0.2 : 0
	}
	
	var body: some View {
		Button {
			self.action()
		} label: {
			Label(
				title,
				systemImage: systemImage
			)
			.foregroundStyle(.secondary)
			.font(.headline)
			.fontWeight(.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal, 8)
			.padding(.vertical, 7)
			.background(
				Color.gray.opacity(self.buttonOpacity)
			)
			.clipShape(
				RoundedRectangle(cornerRadius: 7)
			)
		}
		.buttonStyle(.plain)
		.onHover { hovering in
			withAnimation(
				.linear(duration: 0.3)
			) {
				self.isHovering = hovering
			}
		}
	}
	
}
