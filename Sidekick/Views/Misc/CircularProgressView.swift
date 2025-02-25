//
//  CircularProgressView.swift
//  Sidekick
//
//  Created by John Bean on 2/24/25.
//

import SwiftUI

struct CircularProgressView: View {
	
	@Environment(\.self) var environment
	
	let progress: Double
	
	var width: CGFloat = 15
	
	let fromColor: Color
	let toColor: Color
	
	var color: Color {
		// Get color components
		let resolvedFromColor: Color.Resolved = fromColor.resolve(
			in: environment
		)
		let resolvedToColor: Color.Resolved = toColor.resolve(
			in: environment
		)
		// Calculate component values
		let red: Float = resolvedFromColor.red + (resolvedToColor.red - resolvedFromColor.red) * Float(progress)
		let green: Float = resolvedFromColor.green + (resolvedToColor.green - resolvedFromColor.green) * Float(progress)
		let blue: Float = resolvedFromColor.blue + (resolvedToColor.blue - resolvedFromColor.blue) * Float(progress)
		// Create color
		return Color(
			red: Double(red),
			green: Double(green),
			blue: Double(blue)
		)
	}
	
	var body: some View {
		ZStack {
			Circle()
				.stroke(
					self.color.opacity(0.5),
					lineWidth: width
				)
			progressCircle
		}
	}
	
	var progressCircle: some View {
		Circle()
			.trim(from: 0, to: progress)
			.stroke(
				self.color,
				style: StrokeStyle(
					lineWidth: width,
					lineCap: .round
				)
			)
			.rotationEffect(.degrees(-90))
			.animation(.easeOut, value: progress)
	}
	
}
