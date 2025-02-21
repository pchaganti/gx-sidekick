//
//  DiagrammerPreviewEditorView.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI

struct DiagrammerPreviewEditorView: View {
	
	@EnvironmentObject private var diagrammerViewController: DiagrammerViewController
	
    var body: some View {
		HSplitView {
			editor
				.frame(minWidth: 300)
			ZStack {
				Rectangle()
					.fill(Color.clear)
					.frame(width: 1, height: .greedy)
				self.diagrammerViewController.preview
			}
			.frame(minWidth: 300)
		}
		.toolbar {
			ToolbarItemGroup(placement: .primaryAction) {
				saveButton
				doneButton
			}
		}
    }
	
	var editor: some View {
		TextEditor(text: $diagrammerViewController.d2Code)
			.textEditorStyle(.plain)
			.font(.title3)
			.onChange(of: diagrammerViewController.d2Code) {
				self.diagrammerViewController.saveD2Code()
			}
	}
	
	var saveButton: some View {
		Button {
			self.saveDiagram()
		} label: {
			Text("Save")
		}
		.keyboardShortcut("s", modifiers: [.command])
		.controlSize(.large)
	}
	
	var doneButton: some View {
		Button {
			// Reset
			self.diagrammerViewController.stopRender()
			self.diagrammerViewController.stopPreview()
			self.diagrammerViewController.d2Code = ""
			self.diagrammerViewController.saveD2Code()
			self.diagrammerViewController.currentStep = .prompt
		} label: {
			Text("Done")
		}
		.controlSize(.large)
	}
	
	private func saveDiagram() {
		// Save image
		let saveSuccess: Bool = self.diagrammerViewController.saveImage()
		let message: String = saveSuccess ? String(localized: "Diagram saved successfully") : String(localized: "Failed to save diagram")
		// Show dialog
		Dialogs.showAlert(title: "Save", message: message)
	}
	
}
