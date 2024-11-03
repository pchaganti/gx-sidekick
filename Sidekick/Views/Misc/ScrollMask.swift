//
//  ScrollMask.swift
//  Sidekick
//
//  Created by Bean John on 10/24/24.
//

import SwiftUI

struct ScrollMask: View {
	
	let isLeading: Bool
	
	var body: some View {
		LinearGradient(
			colors: [.black, .clear],
			startPoint: UnitPoint(x: isLeading ? 0 : 1, y: 0.5),
			endPoint: UnitPoint(x: isLeading ? 1 : 0, y: 0.5)
		)
		.frame(width: 50)
		.frame(maxHeight: .infinity)
		.blendMode(.destinationOut)
	}
	
}
