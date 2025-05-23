//
//  SwiftUIView.swift
//  Sidekick
//
//  Created by John Bean on 2/12/25.
//

import SwiftUI

struct LengthyTasksNavigationButton: View {
	
	@State private var isHovering: Bool = false
	
	var buttonOpacity: Double {
		return self.isHovering ? 0.2 : 0
	}
	
	var body: some View {
		LengthyTasksButton()
			.onHover { hovering in
				withAnimation(.linear(duration: 0.3)) {
					self.isHovering = hovering
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal, 8)
			.padding(.top, 7)
			.padding(.bottom, 9)
			.background(
				Color.gray.opacity(self.buttonOpacity)
			)
			.clipShape(
				RoundedRectangle(cornerRadius: 7)
			)
	}
	
}
