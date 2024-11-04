//
//  Extension+View.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

extension View {
	
	@ViewBuilder public func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
		if conditional {
			content(self)
		} else {
			self
		}
	}
	
	public func glow(color: Color = .red, radius: CGFloat = 20, blurred: Bool = true) -> some View {
		return Group {
			if blurred {
				self
					.overlay(self.blur(radius: radius / 6))
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
			} else {
				self
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
			}
		}
	}
	
}
