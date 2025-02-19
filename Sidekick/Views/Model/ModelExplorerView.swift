//
//  ModelsView.swift
//  Sidekick
//
//  Created by John Bean on 2/18/25.
//

import DefaultModels
import SwiftUI

struct ModelExplorerView: View {
	
	@StateObject private var modelExplorerViewController: ModelExplorerViewController = .init()
	
	@State private var modelDownloadUrl: String = "https://huggingface.co/models?sort=trending&search=GGUF"

	let columns = [
		GridItem(.adaptive(minimum: 210))
	]
	
    var body: some View {
		Group {
			if modelExplorerViewController.modelFamilies.isEmpty {
				// Show loading indicator
				loading
			} else {
				NavigationSplitView {
					// Show list of model families to choose from
					VStack {
						familyList
						Link(
							destination: URL(string: modelDownloadUrl)!
						) {
							Text("More Models")
						}
					}
					.padding(.vertical, 5)
					.padding(.bottom, 8)
				} detail: {
					// Show models belonging to the selected family
					if !modelExplorerViewController.selectedFamilyModels.isEmpty {
						modelList
					} else {
						Text("Select a family of models from the sidebar")
							.font(.headline)
							.fontWeight(.regular)
					}
				}
				.navigationTitle(
					modelExplorerViewController.selectedFamily?.name ?? String(localized: "Models")
				)
			}
		}
		.task {
			// Load models from GitHub
			await modelExplorerViewController.loadModelFamilies()
		}
		.onAppear(perform: checkModelUrl)
    }
	
	
	var loading: some View {
		HStack {
			Text("Loading")
			ProgressView()
				.progressViewStyle(.circular)
				.scaleEffect(0.5, anchor: .center)
		}
	}
	
	var familyList: some View {
		List(
			modelExplorerViewController.modelFamilies,
			selection: $modelExplorerViewController.selectedFamily
		) { family in
			NavigationLink(
				value: family
			) {
				Text(family.name)
			}
		}
	}
	
	var modelList: some View {
		ScrollView {
			LazyVGrid(columns: columns, spacing: 10) {
				ForEach(
					modelExplorerViewController.selectedFamilyModels
				) { model in
					ModelView(model: model)
						.listRowSeparator(.hidden)
				}
			}
			.padding()
		}
	}
	
	/// Check if Hugging Face is reachable
	private func checkModelUrl() {
		URL.verifyURL(
			url: URL(string: self.modelDownloadUrl)!,
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
