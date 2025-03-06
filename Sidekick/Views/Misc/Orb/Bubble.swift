//
//  Bubble.swift
//  Sidekick
//
//  Created by John Bean on 3/6/25.
//

import Foundation

struct Bubble: Identifiable {
	
	let id = UUID()
	var size: CGFloat
	var positionX: CGFloat
	var yOffset: CGFloat
	var speed: Double
	var opacity: Double
	
}
