//
//  CheckForUpdatesView.swift
//  Sidekick
//
//  Created by John Bean on 2/11/25.
//

import SwiftUI
import Sparkle

// View model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
	
	@Published var canCheckForUpdates = false
	
	init(updater: SPUUpdater) {
		updater.publisher(for: \.canCheckForUpdates)
			.assign(to: &$canCheckForUpdates)
	}
	
}

// This is the view for the Check for Updates menu item
struct CheckForUpdatesView: View {
	
	@ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
	private let updater: SPUUpdater
	
	init(updater: SPUUpdater) {
		self.updater = updater
		
		// Create our view model for our CheckForUpdatesView
		self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
	}
	
	var body: some View {
		Button {
			self.updater.checkForUpdates()
		} label: {
			Text("Check for Updates")
		}
		.disabled(!checkForUpdatesViewModel.canCheckForUpdates)
	}
	
}
