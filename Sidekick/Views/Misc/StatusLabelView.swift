//
//  StatusLabelView.swift
//  Sidekick
//
//  Created by Bean John on 11/25/24.
//

import SwiftUI

struct StatusLabelView: View {
	
	init(
		text: String,
		textColor: Color? = nil,
		fill: Color
	) {
		self.text = text
		if let textColor {
			self.textColor = textColor
		} else {
			self.textColor = fill.opacity(0.2).adaptedTextColor
		}
		self.fill = fill
	}
	
	var text: String
	var textColor: Color = .primary
	var fill: Color
	
    var body: some View {
		Text(text)
			.font(.caption)
			.foregroundStyle(textColor)
			.bold()
			.padding(2)
			.padding(.horizontal, 2)
			.overlay {
				RoundedRectangle(cornerRadius: 4)
					.fill(fill.opacity(0.2))
					.strokeBorder(fill, lineWidth: 1)
			}
    }
	
	static public var experimental: some View {
		StatusLabelView(
			text: String(localized: "Experimental"),
			textColor: .primary,
			fill: .blue
		)
	}
	
}
