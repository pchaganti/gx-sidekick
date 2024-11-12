//
//  MathView.swift
//  Sidekick
//
//  Created by Bean John on 11/12/24.
//

import SwiftUI
import SwiftMath

struct MathView: NSViewRepresentable {
	
	var equation: String
	var font: MathFont = .latinModernFont
	var textAlignment: MTTextAlignment = .center
	var fontSize: CGFloat = (NSFont.systemFontSize + 1.0) * 1.5
	var labelMode: MTMathUILabelMode = .text
	var insets: MTEdgeInsets = MTEdgeInsets()
	
	func makeNSView(context: Context) -> MTMathUILabel {
		let view = MTMathUILabel()
		return view
	}
	
	func updateNSView(_ view: MTMathUILabel, context: Context) {
		view.latex = equation
		view.font = MTFontManager().font(withName: font.rawValue, size: fontSize)
		view.textAlignment = textAlignment
		view.labelMode = labelMode
		view.textColor = MTColor(Color.primary)
		view.contentInsets = insets
	}
	
}
