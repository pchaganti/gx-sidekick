//
//  PopoverButton.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct PopoverButton<Label: View, Content: View>: View {
	
	init(
		@ViewBuilder label: @escaping () -> Label,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.label = label
		self.content = content
	}
	
	init(
		arrowEdge: Edge,
		@ViewBuilder label: @escaping () -> Label,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.label = label
		self.content = content
		self.arrowEdge = arrowEdge
	}
	
	var label: () -> Label
	var content: () -> Content
	var arrowEdge: Edge = .top
	
	@State private var isShowingPopover: Bool = false
	
	var body: some View {
		Button {
			// Toggle popover state
			isShowingPopover.toggle()
		} label: {
			label()
		}
		.popover(isPresented: $isShowingPopover, arrowEdge: arrowEdge) {
			content()
		}
	}
	
}


#Preview {
	PopoverButton {
		Label("Show Number", systemImage: "eye.fill")
	} content: {
		Text("\(Int.random(in: 0...5))")
			.font(.title)
			.bold()
	}
	.padding()
}
