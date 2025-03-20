//
//  IfFits.swift
//  Sidekick
//
//  Created by John Bean on 3/20/25.
//

import SwiftUI

struct IfFits<Content: View>: View {
	
	let content: () -> Content
	
	var body: some View {
		ViewThatFits {
			content()
			Spacer()
				.frame(width: 0, height: 0)
		}
	}
	
}
