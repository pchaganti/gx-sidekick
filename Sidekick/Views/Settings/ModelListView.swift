//
//  ModelListView.swift
//  Sidekick
//
//  Created by Bean John on 11/8/24.
//

import SwiftUI

struct ModelListView: View {
	
	@Binding var isPresented: Bool
	@StateObject private var modelManager: ModelManager = .shared
	
	@State private var modelUrl: URL? = Settings.modelUrl
	
    var body: some View {
		VStack(
			alignment: .center
		) {
			exitButton
			list
				.frame(
					minHeight: 200,
					maxHeight: 400
				)
			addButton
				.padding(.trailing, 5)
		}
		.padding(7)
		.onChange(
			of: self.modelManager.models
		) {
			self.modelUrl = Settings.modelUrl
		}
		.environmentObject(modelManager)
    }
	
	var list: some View {
		List(
			$modelManager.models,
			editActions: .move
		) { model in
			ModelRowView(
				modelFile: model,
				modelUrl: $modelUrl
			)
		}
		.listRowSeparator(.visible)
	}
	
	var addButton: some View {
		Button {
			let _ = Settings.selectModel()
			self.modelUrl = Settings.modelUrl
		} label: {
			Label(
				"Add Model",
				systemImage: "plus"
			)
		}
		.buttonStyle(.plain)
		.padding(.vertical, 3)
	}
	
	var exitButton: some View {
		HStack {
			ExitButton {
				self.isPresented.toggle()
			}
			.padding([.leading, .top], 3)
			Spacer()
		}
	}

}
