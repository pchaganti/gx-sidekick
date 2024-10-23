//
//  MessageBackgroundView.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import SwiftUI

struct MessageBackgroundView: View {
	
	@Environment(\.colorScheme) private var colorScheme
	
	var shadowColor: SwiftUI.Color {
		return colorScheme == .dark ? .white : .black
	}
	
	var shadowRadius: CGFloat {
		return colorScheme == .dark ? 2.5 : 0
	}
	
    var body: some View {
		UnevenRoundedRectangle(
			cornerRadii: .init(
				topLeading: 0,
				bottomLeading: 12,
				bottomTrailing: 12,
				topTrailing: 12
			),
			style: .circular
		)
		.fill(
			Color(nsColor: .textBackgroundColor)
		)
		.shadow(
			color: shadowColor,
			radius: shadowRadius
		)
    }
}

#Preview {
    MessageBackgroundView()
}
