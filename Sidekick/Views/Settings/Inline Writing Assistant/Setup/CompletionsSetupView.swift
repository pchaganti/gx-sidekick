//
//  CompletionsSetupView.swift
//  Sidekick
//
//  Created by John Bean on 3/25/25.
//

import SwiftUI

struct CompletionsSetupView: View {
	
	@AppStorage("useCompletions") private var useCompletions: Bool = false
	@AppStorage("didSetUpCompletions") private var didSetUpCompletions: Bool = false
	
	@Binding var isPresented: Bool
	@StateObject private var completionsSetupViewModel: CompletionsSetupViewModel = .init()
	
    var body: some View {
		Group {
			switch self.completionsSetupViewModel.step {
				case .nextTokenTutorial, .allTokensTutorial:
					CompletionsTutorialView()
				case .downloadModel:
					CompletionsDownloadView()
				case .done:
					SetupCompleteView(
						description: String(localized: "Completions is now ready to use!")
					) {
						// Mark as done
						self.useCompletions = true
						self.didSetUpCompletions = true
						// Hide sheet
						self.isPresented = false
					}
					.padding(7)
					.padding(.vertical, 5)
			}
		}
		.padding(7)
		.environmentObject(completionsSetupViewModel)
    }
	
	
}
