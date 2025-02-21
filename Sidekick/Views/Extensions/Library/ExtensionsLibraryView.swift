//
//  ExtensionLibraryView.swift
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
		count: 2
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
			self.openWindow(id: "diagrammer")
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
		}
	}
	
}
