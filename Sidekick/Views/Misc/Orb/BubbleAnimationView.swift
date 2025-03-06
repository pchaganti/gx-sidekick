//
//  BubbleAnimationView.swift
//  Sidekick
//
//  Created by John Bean on 3/6/25.
//

import SwiftUI

struct BubbleAnimationView: View {
	
	@State private var bubbles: [Bubble] = []
	
	var body: some View {
		ZStack {
			ForEach(bubbles.indices, id: \.self) { index in
				Circle()
					.frame(width: bubbles[index].size, height: bubbles[index].size)
					.position(x: bubbles[index].positionX, y: bubbles[index].yOffset)
					.opacity(bubbles[index].opacity)
					.onAppear {
						animateBubble(at: index)
					}
					.foregroundStyle(.white)
			}
		}
		.frame(width: 50, height: 50)
		.onAppear(perform: createBubbles)
	}
	
	func createBubbles() {
		for _ in 0..<50 {
			let size = CGFloat.random(in: 1...3)
			let positionX = CGFloat.random(in: 0...100)
			let positionY = 100
			let speed = Double.random(in: 2.0...5.0)
			let opacity = Double.random(in: 0.5...1.0)
			let bubble = Bubble(
				size: size,
				positionX: positionX,
				yOffset: CGFloat(positionY),
				speed: speed,
				opacity: opacity
			)
			bubbles.append(bubble)
		}
	}
	
	private func animateBubble(at index: Int) {
		let delay = Double.random(in: 0...2)
		DispatchQueue.main.asyncAfter(
			deadline: .now() + delay
		) {
			withAnimation(.linear(
				duration: bubbles[index].speed
			).repeatForever(autoreverses: false)) {
				bubbles[index].yOffset = 0
				bubbles[index].opacity = 0
			}
		}
	}
	
}
