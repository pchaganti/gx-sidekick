//
//  DictationButton.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import SwiftUI

struct DictationButton: View {
	
	@EnvironmentObject private var promptController: PromptController
	
	var dictationTip: DictationTip = .init()
	
    var body: some View {
		Button {
			withAnimation(.linear) {
				self.promptController.toggleRecording()
			}
		} label: {
			Label("", systemImage: "microphone.fill")
				.foregroundStyle(
					promptController.isRecording ? .red : .secondary
				)
		}
		.buttonStyle(.plain)
		.padding([.trailing, .bottom], 3)
		.popoverTip(dictationTip)
    }
}

#Preview {
    DictationButton()
}
