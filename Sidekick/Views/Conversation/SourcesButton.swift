//
//  SourcesButton.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import SwiftUI
import SwiftUIX

struct SourcesButton: View {
	
	@Binding var showSources: Bool
	
	var body: some View {
		Button {
			showSources.toggle()
		} label: {
			Image(systemName: "book.circle")
				.imageScale(.medium)
				.background(.clear)
				.imageScale(.small)
				.padding(.leading, 1)
				.padding(.horizontal, 3)
				.frame(width: 15, height: 15)
				.scaleEffect(CGSize(width: 0.96, height: 0.96))
				.background(.primary.opacity(0.00001)) // Needs to be clickable
		}
		.buttonStyle(.plain)
	}
	
}

//#Preview {
//    StopGenerationButton()
//}
