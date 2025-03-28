//
//  SlideStudioPreviewEditor.swift
//  Sidekick
//
//  Created by John Bean on 2/28/25.
//

import CodeEditorView
import LanguageSupport
import SwiftUI

struct SlideStudioPreviewEditor: View {
	
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	@Environment(\.dismissWindow) private var dismissWindow
	
	@EnvironmentObject private var slideStudioViewController: SlideStudioViewController
	@State private var position: CodeEditor.Position = CodeEditor.Position()
	@State private var messages: Set<TextLocated<LanguageSupport.Message>> = Set()
	
	@State private var showExportOptions: Bool = false
	
	@State private var previewId: UUID = UUID()
	
	var refreshButtonSymbolName: String {
		if #available(macOS 15, *) {
			return "arrow.trianglehead.counterclockwise"
		}
		return "gobackward"
	}
	
    var body: some View {
		HSplitView {
			editor
				.frame(minWidth: 300)
			ZStack {
				Rectangle()
					.fill(Color.clear)
					.frame(width: 1, height: .greedy)
				self.slideStudioViewController.preview
					.overlay(alignment: .topTrailing) {
						refreshButton
							.padding([.top, .trailing], 6)
					}
					.id(previewId)
			}
			.frame(minWidth: 300)
		}
		.toolbar {
			ToolbarItemGroup(
				placement: .primaryAction
			) {
				newButton
				exportButton
				exitButton
			}
		}
		.sheet(isPresented: $showExportOptions) {
			SlideStudioExportOptionsView(
				isPresented: $showExportOptions
			)
			.frame(
				maxWidth: 600,
				maxHeight: 750
			)
		}
    }
	
	var editor: some View {
		CodeEditor(
			text: self.$slideStudioViewController.markdown,
			position: self.$position,
			messages: self.$messages
		)
		.environment(
			\.codeEditorTheme, self.colorScheme == .dark ? Theme.defaultDark : Theme.defaultLight
		)
		.onChange(
			of: self.slideStudioViewController.markdown
		) {
			self.slideStudioViewController.saveMarkdownToFile()
		}
	}
	
	var newButton: some View {
		Button {
			// Reset
			self.slideStudioViewController.reset()
		} label: {
			Text("New Slides")
		}
	}
	
	var refreshButton: some View {
		Button {
			// Restart server
			self.slideStudioViewController.stopPreview()
			self.slideStudioViewController.startPreview()
			// Reset id to redraw view
			self.previewId = UUID()
		} label: {
			Label("Refresh", systemImage: refreshButtonSymbolName)
				.labelStyle(.iconOnly)
				.foregroundStyle(Color.white)
		}
		.buttonStyle(.plain)
		.padding([.horizontal, .bottom], 8)
		.padding(.top, 7)
		.background {
			Circle()
				.fill(Color(nsColor: .darkGray))
		}
	}
	
	var exportButton: some View {
		Button {
			self.showExportOptions.toggle()
		} label: {
			Text("Export")
		}
	}
	
	var exitButton: some View {
		Button {
			// Reset
			self.slideStudioViewController.reset()
			// Close window
			self.dismissWindow(id: "slideStudio")
		} label: {
			Text("Exit")
		}
		.controlSize(.large)
	}
	
}
