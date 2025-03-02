//
//  SlideStudioView.swift
//  Sidekick
//
//  Created by John Bean on 2/28/25.
//

import SwiftUI

struct SlideStudioView: View {
	
	@StateObject private var slideStudioViewController: SlideStudioViewController = .init()
	
    var body: some View {
		Group {
			switch self.slideStudioViewController.currentStep {
				case .prompt:
					SlideStudioPromptView()
				case .previewEditor:
					SlideStudioPreviewEditor()
				default:
					SlideStudioProgressView()
			}
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: NSApplication.willTerminateNotification
			)
		) { output in
			// Stop server before app is quit
			self.slideStudioViewController.stopPreview()
			
		}
		.environmentObject(slideStudioViewController)
    }
	
}
