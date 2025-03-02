//
//  DiagrammerView.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI

struct DiagrammerView: View {
	
	@EnvironmentObject private var model: Model
	@StateObject private var diagrammerViewController: DiagrammerViewController = .init()
	
    var body: some View {
		Group {
			switch self.diagrammerViewController.currentStep {
				case .prompt:
					DiagrammerPromptView()
				case .generating:
					DiagrammerGeneratingView()
				case .editAndPreview:
					DiagrammerPreviewEditorView()
			}
		}
		.environmentObject(diagrammerViewController)
		.onReceive(
			NotificationCenter.default.publisher(
				for: NSApplication.willTerminateNotification
			)
		) { output in
			// Stop server before app is quit
			self.diagrammerViewController.stopPreview()
			self.diagrammerViewController.stopRender()
		}
    }
	
}
