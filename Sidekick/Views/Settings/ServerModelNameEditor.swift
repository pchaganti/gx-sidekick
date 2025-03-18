//
//  ServerModelNameEditor.swift
//  Sidekick
//
//  Created by John Bean on 3/12/25.
//

import SwiftUI

struct ServerModelNameEditor: View {
	
	@AppStorage("endpoint") private var serverEndpoint: String = InferenceSettings.endpoint
	@Binding var serverModelName: String
	
	var modelType: ModelType
	
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
	
	/// A localized `String` containing the title shown for the editor
	var editorTitle: String {
		switch self.modelType {
			case .regular:
				return String(localized: "Remote Model Name")
			case .worker:
				return String(localized: "Remote Worker Model Name")
		}
	}
	
	/// A localized `String` containing the description shown for the editor
	var editorDescription: String {
		switch self.modelType {
			case .regular:
				return String(localized: "The model's name. (e.g. gpt-4o)")
			case .worker:
				return String(localized: "The worker model's name. (e.g. gpt-4o-mini) The worker model is used for simpler tasks like generating chat titles.\n\nLeave this blank to use the main model for all tasks.")
		}
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
					TextField("", text: self.$serverModelName)
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
			Text(self.editorTitle)
				.font(.title3)
				.bold()
			Text(self.editorDescription)
				.font(.caption)
		}
	}
	
	var modelList: some View {
		Picker(
			selection: $serverModelName
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
