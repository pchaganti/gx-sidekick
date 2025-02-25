//
//  DetectorInputView.swift
//  Sidekick
//
//  Created by John Bean on 2/24/25.
//

import SwiftUI

struct DetectorInputView: View {
	
	@EnvironmentObject private var detectorViewController: DetectorViewController
	
    var body: some View {
		ScrollView {
			TextEditor(
				text: $detectorViewController.text
			)
			.textEditorStyle(.plain)
			.frame(minHeight: 1000)
			.scrollIndicators(.hidden)
			.font(.title3)
			.padding([.vertical, .leading])
		}
		.toolbar {
			ToolbarItemGroup(
				placement: .primaryAction
			) {
				analyzeButton
			}
		}
    }
	
	var analyzeButton: some View {
		Button {
			Task.detached { @MainActor in
				await self.detectorViewController.evaluateText()
			}
		} label: {
			Text("Analyze")
		}
		.controlSize(.large)
	}
	
}
