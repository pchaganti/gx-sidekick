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
			Circle()
				.fill(Color.clear)
				.frame(width: 32, height: 32)
				.overlay {
					Square()
						.fill(Color.primary)
						.padding(8)
				}
		}
		.buttonStyle(ChatButtonStyle())
    }
	
	func stopGeneration() {
		Task.detached { @MainActor in
			await self.model.interrupt()
		}
	}
	
}

//#Preview {
//    StopGenerationButton()
//}
