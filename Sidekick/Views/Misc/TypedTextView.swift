//
//  TypedTextView.swift
//  Sidekick
//
//  Created by Bean John on 10/31/24.
//

import SwiftUI

struct TypedTextView: View {
	
	init(
		_ text: String,
		duration: Double = 1.0,
		didFinish: Binding<Bool>,
		onFinish: (() -> Void)? = nil
	) {
		self.text = text
		self.duration = duration
		self._didFinish = didFinish
		self.onFinish = onFinish
	}
	
	var text: String
	var duration: Double
	var onFinish: (() -> Void)?
	
	@Binding var didFinish: Bool
	@State private var timer: Timer?
	@State private var displayedText: String = ""
	
	var body: some View {
		Group {
			Text(displayedText)
		}
		.onAppear(perform: setTimer)
		.onChange(of: text) {
			setTimer()
		}
	}
	
	private func setTimer() {
		let interval: Double = duration / Double(text.count)
		timer?.invalidate()
		self.didFinish = false
		timer = Timer.scheduledTimer(
			withTimeInterval: interval,
			repeats: true
		) { _ in
			// Cancel timer when done
			if displayedText == text {
				timer?.invalidate()
				self.didFinish = true
				// Run handler
				self.onFinish?()
			}
			// Add 1 character
			let character: String = self.text[displayedText.count]
			displayedText.append(character)
		}
	}
	
	
	
}
