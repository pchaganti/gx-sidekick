//
//  MessageBackgroundView.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import SwiftUI

struct MessageBackgroundView: View {
	
	private let cornerRadius: CGFloat = 13
	private let borderWidth: CGFloat = 0.5
	
	var body: some View {
		unevenRoundedRectangle(cornerRadius)
			.fill(
				Color(nsColor: .textBackgroundColor)
			)
			.padding(borderWidth)
			.background {
				unevenRoundedRectangle(cornerRadius + borderWidth)
					.fill(Color.secondary)
					.opacity(0.5)
			}
	}
	
	private func unevenRoundedRectangle(
		_ cornerRadius: CGFloat
	) -> some Shape {
		UnevenRoundedRectangle(
			cornerRadii: .init(
				topLeading: 0,
				bottomLeading: cornerRadius,
				bottomTrailing: cornerRadius,
				topTrailing: cornerRadius
			),
			style: .circular
		)
	}
	
}

#Preview {
    MessageBackgroundView()
}
