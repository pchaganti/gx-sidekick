//
//  LiquidView.swift
//  Sidekick
//
//  Created by John Bean on 3/6/25.
//

import SwiftUI

struct CircleData: Identifiable {
	
	let id = UUID()
	let size: CGFloat
	var xOffset: CGFloat
	var yOffset: CGFloat
	var xSpeed: CGFloat
	var ySpeed: CGFloat
	
}

struct LiquidView: View {
	
	@State private var circles: [CircleData] = []
	
	var movementRange: CGFloat = 10
	let animationInterval: TimeInterval = 0.02
	let circleCount = 20
	
	var body: some View {
		Canvas { context, size in
			_ = CGRect(
				x: size.width / 2 - 100,
				y: size.height / 2 + 40,
				width: 100,
				height: 100
			)
			
			context.addFilter(.alphaThreshold(min: 0.4))
			context.addFilter(.blur(radius: 4))
			
			context.drawLayer { drawingContext in
				for circle in circles {
					let circleRect = CGRect(
						x: circle.xOffset + size.width / 2 - circle.size / 2,
						y: circle.yOffset + size.height / 2 - circle.size / 2,
						width: circle.size,
						height: circle.size
					)
					drawingContext.fill(Path(ellipseIn: circleRect), with: .color(.blue))
				}
			}
		}
		.onAppear {
			setupCircles()
			startAnimation()
		}
	}
	
	func setupCircles() {
		circles = (0..<circleCount).map { _ in
			CircleData(
				size: CGFloat.random(in: 10...30),
				xOffset: CGFloat.random(in: -movementRange / 2...movementRange / 2),
				yOffset: CGFloat.random(in: -movementRange / 2...movementRange / 2),
				xSpeed: CGFloat.random(in: -0.1...0.1),
				ySpeed: CGFloat.random(in: -0.1...0.1)
			)
		}
	}
	
	func startAnimation() {
		Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { _ in
			DispatchQueue.main.async {
				circles.indices.forEach { index in
					circles[index].xOffset += circles[index].xSpeed
					circles[index].yOffset += circles[index].ySpeed
					
					if abs(circles[index].xOffset) > movementRange / 2 {
						circles[index].xSpeed *= -1
					}
					if abs(circles[index].yOffset) > movementRange / 2 {
						circles[index].ySpeed *= -1
					}
				}
			}
		}
	}
}
