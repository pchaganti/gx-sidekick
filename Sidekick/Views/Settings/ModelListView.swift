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
	
	@State private var modelUrl: URL? = nil
	
	@State private var modelDownloadUrl: String = "https://huggingface.co/models?sort=trending&search=GGUF"
	
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
		.onAppear(perform: checkModelUrl)
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
			if !self.forSpeculativeDecoding {
				let _ = Settings.selectModel()
				self.modelUrl = Settings.modelUrl
			} else {
				let _ = modelManager.addModel()
			}
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
			Spacer()
			PopoverButton {
				Image(systemName: "questionmark.circle.fill")
			} content: {
				Link(
					destination: URL(string: modelDownloadUrl)!
				) {
					Text("Download More Models")
				}
				.padding(8)
				.padding(.horizontal, 2)
			}
			.buttonStyle(.plain)
		}
		.padding([.horizontal, .top], 3)
	}
	
	/// Check if Hugging Face is reachable
	private func checkModelUrl() {
		URL.verifyURL(
			urlPath: self.modelDownloadUrl,
			timeoutInterval: 1
		) { isValid in
			if !isValid {
				self.modelDownloadUrl = self.modelDownloadUrl.replacingOccurrences(
					of: "huggingface.co",
					with: "hf-mirror.com"
				)
			}
		}
	}

}
