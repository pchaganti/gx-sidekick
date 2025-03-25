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
					SetupCompleteView(
						description: String(localized: "Sidekick is ready to use.")
					) {
						Settings.finishSetup()
						self.showSetup = false
					}
					.frame(maxHeight: 400)
				default:
					IntroductionPageView(
						content: introductionViewController.page.content!
					)
			}
		}
	}
	
}
