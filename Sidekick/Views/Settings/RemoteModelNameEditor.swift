//
//  RemoteModelNameEditor.swift
//  Sidekick
//
//  Created by John Bean on 3/12/25.
//

import SwiftUI

struct RemoteModelNameEditor: View {
	
	@AppStorage("endpoint") private var serverEndpoint: String = InferenceSettings.endpoint
	@AppStorage("remoteModelName") private var remoteModelName: String = InferenceSettings.remoteModelName
	
	var showModelList: Bool {
		if !self.modelNames.isEmpty && !self.isFocused {
			return true
		} else if self.modelNames.isEmpty {
			return false
		}
		return true
	}
	var toggleLabel: String {
		if !showModelList {
			return "Select from List"
		}
		return "Manual Entry"
	}
	
	@FocusState var isFocused: Bool
	@State private var modelNames: [String] = []
	
	var body: some View {
		HStack(alignment: .center) {
			description
			Spacer()
			VStack(
				alignment: .trailing
			) {
				if !showModelList {
					TextField("", text: self.$remoteModelName)
						.focused(self.$isFocused)
						.textFieldStyle(.roundedBorder)
						.frame(maxWidth: 250)
				} else {
					modelList
				}
			}
		}
		.task {
			await self.refreshModelNames()
		}
		.onChange(of: serverEndpoint) {
			Task { @MainActor in
				await self.refreshModelNames()
			}
		}
	}
	
	var description: some View {
		VStack(alignment: .leading) {
			Text("Remote Model Name")
				.font(.title3)
				.bold()
			Text("The model name on the server used for inference. (e.g. gpt-4o)")
				.font(.caption)
		}
	}
	
	var modelList: some View {
		Picker(
			selection: $remoteModelName
		) {
			ForEach(modelNames, id: \.self) { modelName in
				Text(modelName)
					.tag(modelName)
			}
		}
		.pickerStyle(.menu)
		.frame(maxWidth: 250)
	}
	
	private func refreshModelNames() async {
		self.modelNames = await LlamaServer.getAvailableModels()
	}
	
}
