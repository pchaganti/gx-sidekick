//
//  CircleMenuStyle.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct CircleMenuStyle: MenuStyle {
	
	func makeBody(configuration: Configuration) -> some View {
		Menu(configuration)
			.menuStyle(.button)
			.buttonStyle(.plain)
			.padding(1)
			.foregroundStyle(.secondary)
	}
	
}

extension MenuStyle where Self == CircleMenuStyle {
	
	static var circle: CircleMenuStyle { CircleMenuStyle() }
	
}
