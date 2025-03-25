//
//  CompletionsTutorialView.swift
//  Sidekick
//
//  Created by John Bean on 3/25/25.
//

import MarkdownUI
import SwiftUI

struct CompletionsTutorialView: View {
	
	@EnvironmentObject private var completionsSetupViewModel: CompletionsSetupViewModel
	
	let chunks: [String] = "The quick brown fox jumps over the lazy dog."
		.split(separator: " ")
		.map({ String($0) })
	
	@State private var words: Int = 2
	@FocusState private var focused: Bool
	
	var text: String {
		return chunks
			.dropLast(max(chunks.count - words, 0))
			.joined(separator: " ")
	}
	
	var completionSuggestion: String {
		let remainingChunks = chunks.dropFirst(words)
		let suggestedChunks: Int = 3
		return " " + remainingChunks
			.dropLast(max(remainingChunks.count - suggestedChunks, 0))
			.joined(separator: " ")
	}
	
	var completeByWord: Bool {
		return completionsSetupViewModel.step == .nextTokenTutorial
	}
	
	var instruction: String {
		switch completionsSetupViewModel.step {
			case .nextTokenTutorial:
				return String(localized: "Press `Tab` to accept a suggested word")
			default:
				return String(localized: "Press `Shift + Tab` to accept a suggested phrase")
		}
	}
	
    var body: some View {
		VStack {
			Markdown(instruction)
				.bold()
			Divider()
			preview
				.padding(.vertical, 50)
			Divider()
			HStack {
				Spacer()
				nextButton
					.disabled(self.words < self.chunks.count)
			}
		}
		.onChange(
			of: self.completionsSetupViewModel.step
		) {
			self.reset()
		}
		.if(completeByWord) { view in
			view
				.focusable()
				.focused($focused)
				.focusEffectDisabled()
				.onAppear {
					focused = true
				}
				.onKeyPress(.tab) {
					withAnimation(
						.linear(duration: 0.1)
					) {
						self.words = min(
							self.words + 1,
							self.chunks.count
						)
					}
					return .handled
				}
		}
		.if(!completeByWord) { view in
			view
				.onKeyboardShortcut(
					.tab,
					modifiers: .shift
				) {
					withAnimation(
						.linear(duration: 0.1)
					) {
						self.words = min(
							self.words + 3,
							self.chunks.count
						)
					}
				}
		}
		.padding(3)
    }
	
	var preview: some View {
		HStack {
			Text(text) + Text(completionSuggestion).foregroundStyle(.secondary.opacity(0.7))
			Spacer()
		}
		.font(.title3)
		.bold()
	}
	
	var nextButton: some View {
		Button {
			self.reset()
			self.completionsSetupViewModel.step.nextCase()
		} label: {
			Text("Next")
		}
		.controlSize(.large)
	}
	
	/// Function to reset the tutorial
	private func reset() {
		self.words = 2
	}
	
}
