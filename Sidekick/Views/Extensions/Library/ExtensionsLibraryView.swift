//
//  ExtensionsLibraryView.swift
//  Sidekick
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI

struct ExtensionsLibraryView: View {
	
	@Environment(\.openWindow) var openWindow
	
	@Binding var isPresented: Bool
	@State private var showAssistantInstructionSheet: Bool = false
	
	let columns: [GridItem] = Array(
		repeating: GridItem(.fixed(180)),
		count: 3
	)
	
    var body: some View {
		VStack(
			spacing: 5
		) {
			HStack {
				ExitButton {
					self.isPresented.toggle()
				}
				Spacer()
			}
			extensions
				.padding(.horizontal, 5)
		}
		.padding(8)
		.padding(.bottom, 8)
    }
	
	var extensions: some View {
		ScrollView {
			LazyVGrid(
				columns: columns,
				spacing: 5
			) {
				self.diagrammerCard
				self.inlineAssistantCard
				self.detectorCard
			}
		}
	}
	
	var diagrammerCard: some View {
		ExtensionCardButton(
			name: String(localized: "Diagrammer"),
			description: String(localized: "Generate diagrams with AI"),
			isSvg: true
		) {
			Image("mindmap")
		} action: {
			self.openExtensionWindow(id: "diagrammer")
		}
	}
	
	var inlineAssistantCard: some View {
		ExtensionCardButton(
			name: String(localized: "Inline Assistant"),
			description: String(localized: "Edit text with AI without leaving your editor"),
			isSvg: false
		) {
			Image(systemName: "pencil.and.list.clipboard")
		} action: {
			self.showAssistantInstructionSheet.toggle()
		}
		.sheet(isPresented: $showAssistantInstructionSheet) {
			AssistantInstructionView(
				showAssistantInstructionSheet: $showAssistantInstructionSheet
			)
			.frame(
				maxWidth: 450,
				maxHeight: 400
			)
		}
	}
	
	var detectorCard: some View {
		ExtensionCardButton(
			name: String(localized: "Detector"),
			description: String(localized: "Stay one step ahead of Turnitin")
		) {
			Image(systemName: "doc.text.magnifyingglass")
		} action: {
			self.openExtensionWindow(id: "detector")
		}
	}
	
	/// Function to open an extension's associated window
	private func openExtensionWindow(
		id: String
	) {
		// Open window & close sheet
		self.openWindow(id: id)
		self.isPresented.toggle()
	}
	
}
