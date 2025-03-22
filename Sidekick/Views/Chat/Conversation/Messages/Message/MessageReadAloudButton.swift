//
//  MessageReadAloudButton.swift
//  Sidekick
//
//  Created by John Bean on 3/22/25.
//

import SwiftUI

struct MessageReadAloudButton: View {
	
	@StateObject private var speechSynthesizer: SpeechSynthesizer = .shared
	
	var message: Message
	
	private var isGenerating: Bool {
		return !message.outputEnded && message.getSender() == .assistant
	}
	
	@State private var isReading: Bool = false
	
	var imageName: String {
		return !self.isReading ? "speaker.wave.3" : "speaker.slash.fill"
	}
	
    var body: some View {
		Button {
			// Toggle reading
			if self.isReading {
				self.stopReading()
			} else {
				self.startReading()
			}
			// Toggle flag
			withAnimation(.linear) {
				self.isReading.toggle()
			}
		} label: {
			Image(systemName: self.imageName)
				.foregroundStyle(.secondary)
		}
		.buttonStyle(.plain)
		.disabled(self.isGenerating)
    }
	
	/// Function to start reading the response
	private func startReading() {
		// Get response text
		let text: String = message.hasReasoning ? message.responseText : message.text
		// Start TTS
		Task { @MainActor in
			await speechSynthesizer.speak(
				text: text
			) {
				withAnimation(.linear) {
					self.isReading = false // Reset on complete
				}
			}
		}
	}
	
	/// Function to stop reading the response
	private func stopReading() {
		// End TTS
		Task {
			await speechSynthesizer.stopSpeaking()
		}
	}
	
}
