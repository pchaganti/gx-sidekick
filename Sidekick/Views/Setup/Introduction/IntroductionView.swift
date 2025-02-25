//
//  IntroductionView.swift
//  Sidekick
//
//  Created by Bean John on 9/23/24.
//

import SwiftUI
import Combine

struct IntroductionView: View {
	
	@EnvironmentObject private var conversationState: ConversationState
	
	@StateObject private var introductionViewController: IntroductionViewController = .init()
	
	@Binding var showSetup: Bool
	
    var body: some View {
		HStack {
			introductionViewController.prevPage
			VStack {
				page
					.padding()
				// Progress indicator
				if introductionViewController.page.hasNext {
					introductionViewController.progress
				}
			}
			introductionViewController.nextPage
		}
		.frame(maxHeight: 500)
    }
	
	var page: some View {
		Group {
			switch introductionViewController.page {
				case .done:
					done
				default:
					IntroductionPageView(
						content: introductionViewController.page.content!
					)
			}
		}
	}
	
	var done: some View {
		VStack {
			Image(systemName: "checkmark.circle.fill")
				.resizable()
				.frame(width: 60, height: 60)
				.foregroundColor(.green)
				.imageScale(.large)
			Text("**Setup Complete**")
				.font(.largeTitle)
			Text("Sidekick is ready to use.")
				.font(.title3)
			Button {
				Settings.finishSetup()
				self.showSetup = false
			} label: {
				Text("Continue")
			}
			.buttonStyle(.borderedProminent)
			.controlSize(.large)
			.padding(.top, 16)
			.padding(.horizontal, 40)
			.keyboardShortcut(.defaultAction)
		}
	}
	
}
