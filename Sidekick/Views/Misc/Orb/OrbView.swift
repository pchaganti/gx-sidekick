//
//  OrbView.swift
//  Sidekick
//
//  Created by John Bean on 3/6/25.
//

import SwiftUI

struct OrbView: View {

	@State private var liquidColor: Color = .indigo
	@State private var line: Bool = false
	@State private var rotation: Bool = false
	
	var size: Self.Size = .small
	
    var body: some View {
		ZStack {
			self.liquidColor
				.mask(
					LiquidView()
						.scaleEffect(self.size.rawValue)
				)
				.blur(radius: 2 * self.size.rawValue)
				.background(self.liquidColor.opacity(0.3))
				.background (
					Color.orbBg
						.shadow(
							.inner(
								color: Color.white.opacity(0.5),
								radius: 2 * self.size.rawValue,
								x: line ? self.size.rawValue : 0,
								y: 0
							)
						),
					in: .circle
				)
				.rotationEffect(.degrees(self.rotation ? 360 : 0))
			Circle()
				.frame(
					width: 20 * self.size.rawValue,
					height: 20 * self.size.rawValue
				)
				.blur(radius: 10 * self.size.rawValue)
				.offset(y: -10 * self.size.rawValue)
				.rotationEffect(.degrees(self.rotation ? 360 : 0))
		}
		.frame(width: 50 * self.size.rawValue, height: 50 * self.size.rawValue)
		.clipShape(Circle())
		.overlay {
			Image(systemName: "sparkles")
				.foregroundStyle(.white)
				.font(.system(size: 22.5 * self.size.rawValue))
				.shadow(
					color: .white,
					radius: 1.5 * self.size.rawValue,
					x: 0,
					y: 0
				)
		}
		.onAppear {
			self.setupAnimation()
		}
    }
	
	private func setupAnimation() {
		withAnimation(
			.easeInOut(duration: 6)
			.repeatForever(autoreverses: true)
		) {
			self.line.toggle()
		}
		withAnimation(
			.easeInOut(duration: 7)
			.repeatForever(autoreverses: false)
		) {
			self.rotation.toggle()
		}
	}
	
	public enum Size: CGFloat, CaseIterable {
		case extraSmall = 1
		case small = 2
		case medium = 4
		case large = 6
		case extraLarge = 8
	}
	
}
