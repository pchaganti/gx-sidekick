//
//  ModelListView.swift
//  Sidekick
//
//  Created by Bean John on 11/8/24.
//

import SwiftUI

struct ModelListView: View {
	
	init(
		isPresented: Binding<Bool>,
		forSpeculativeDecoding: Bool = false
	) {
		self._isPresented = isPresented
		self.forSpeculativeDecoding = forSpeculativeDecoding
	}
	
	var forSpeculativeDecoding: Bool = false
	
	@Binding var isPresented: Bool
	@StateObject private var modelManager: ModelManager = .shared
	
	@Environment(\.openWindow) var openWindow
	
	@State private var modelUrl: URL? = nil
	
	@State private var hoveringAdd: Bool = false
	@State private var hoveringDownload: Bool = false
	
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
			HStack {
				addButton
				downloadButton
			}
			.padding(.vertical, 3)
			.padding(.bottom, 3)
		}
		.padding(7)
		.onChange(
			of: self.modelManager.models
		) {
			self.modelUrl = {
				if !self.forSpeculativeDecoding {
					return Settings.modelUrl
				}
				return InferenceSettings.speculativeDecodingModelUrl
			}()
		}
		.onAppear {
			self.modelUrl = {
				if !self.forSpeculativeDecoding {
					return Settings.modelUrl
				}
				return InferenceSettings.speculativeDecodingModelUrl
			}()
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
				modelUrl: $modelUrl,
				forSpeculativeDecoding: forSpeculativeDecoding
			)
		}
		.listRowSeparator(.visible)
	}
	
	var addButton: some View {
		Button {
			self.addModel()
		} label: {
			Label(
				"Add Model",
				systemImage: "plus"
			)
		}
		.buttonStyle(.plain)
		.padding(5)
		.padding(.horizontal, 5)
		.background {
			RoundedRectangle(cornerRadius: 7)
				.fill(
					Color.secondary.opacity(self.hoveringAdd ? 0.15 : 0)
				)
				.frame(height: 30)
		}
		.onHover { hovering in
			self.hoveringAdd = hovering
		}
	}
	
	var downloadButton: some View {
		Button {
			self.openWindow(id: "models")
		} label: {
			Label(
				"Download Model",
				systemImage: "square.and.arrow.down"
			)
		}
		.buttonStyle(.plain)
		.padding(.bottom, 6)
		.padding(.top, 4)
		.padding(.horizontal, 5)
		.background {
			RoundedRectangle(cornerRadius: 7)
				.fill(
					Color.secondary.opacity(self.hoveringDownload ? 0.15 : 0)
				)
				.frame(height: 30)
		}
		.onHover { hovering in
			self.hoveringDownload = hovering
		}
	}
	
	var exitButton: some View {
		HStack {
			ExitButton {
				self.isPresented.toggle()
			}
			Spacer()
		}
		.padding([.horizontal, .top], 3)
	}
	
	/// Function to add model
	private func addModel() {
		if !self.forSpeculativeDecoding {
			let _ = Settings.selectModel()
			self.modelUrl = Settings.modelUrl
		} else {
			let _ = modelManager.addModel()
		}
		// Send notification to reload model
		NotificationCenter.default.post(
			name: Notifications.changedInferenceConfig.name,
			object: nil
		)
	}

}
