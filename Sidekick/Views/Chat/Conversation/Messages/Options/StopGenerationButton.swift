//
//  StopGenerationButton.swift
//  Sidekick
//
//  Created by Bean John on 10/17/24.
//

import SwiftUI
import SwiftUIX

struct StopGenerationButton: View {
	
	@EnvironmentObject private var model: Model
	
    var body: some View {
		Button {
			self.stopGeneration()
		} label: {
			Image(systemName: "stop.circle")
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
	
	private func stopGeneration() {
		Task.detached { @MainActor in
			await self.model.interrupt()
		}
	}
	
}

//#Preview {
//    StopGenerationButton()
//}
