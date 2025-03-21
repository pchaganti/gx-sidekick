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
	
	@State private var customModelNames: [String] = InferenceSettings.customModelNames
	@State private var isAddingCustomModel: Bool = false

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
			modelList
		}
		.task {
			await self.refreshModelNames()
		}
		.onChange(of: serverEndpoint) {
			Task { @MainActor in
				await self.refreshModelNames()
			}
		}
		.sheet(
			isPresented: self.$isAddingCustomModel
		) {
			CustomModelsEditor(
				customModelNames: self.$customModelNames,
				isPresented: self.$isAddingCustomModel
			)
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
		Menu {
			Group {
				// Show API models
				ForEach(modelNames, id: \.self) { modelName in
					Button {
						self.serverModelName = modelName
					} label: {
						Text(modelName)
					}
				}
				Divider()
				// Show custom models
				ForEach(customModelNames, id: \.self) { modelName in
					Button {
						self.serverModelName = modelName
					} label: {
						Text(modelName)
					}
				}
				Divider()
				Button {
					self.isAddingCustomModel = true
				} label: {
					Text("Add Custom Model")
				}
			}
		} label: {
			Text(self.serverModelName)
		}
		.frame(maxWidth: 150)
	}
	
	private func refreshModelNames() async {
		self.modelNames = await LlamaServer.getAvailableModels()
	}
	
	struct CustomModelsEditor: View {
		
		@Binding var customModelNames: [String]
		@Binding var isPresented: Bool
		
		var body: some View {
			VStack(
				alignment: .leading
			) {
				List(
					self.$customModelNames,
					id: \.self
				) { modelName in
					HStack {
						CustomModelsEditorField(modelName: modelName)
						Spacer()
						Button {
							// Remove from list
							withAnimation(.linear) {
								self.customModelNames = self.customModelNames.filter { name in
									return name != modelName.wrappedValue
								}
							}
						} label: {
							Label("Delete", systemImage: "trash")
								.foregroundStyle(.red)
								.labelStyle(.iconOnly)
						}
						.buttonStyle(.plain)
					}
				}
				.frame(minHeight: 200, maxHeight: 300)
				Divider()
				HStack {
					Spacer()
					addButton
					doneButton
				}
				.controlSize(.large)
				.padding([.bottom, .trailing], 12)
			}
			.onAppear {
				print("Redrew editor")
			}
			.onDisappear {
				withAnimation(.linear) {
					// Filter and save
					self.filterAndSaveModels()
				}
			}
		}
		
		var addButton: some View {
			Button {
				// Add
				withAnimation(.linear) {
					self.customModelNames.append("")
				}
			} label: {
				Text("Add")
			}
		}
		
		var doneButton: some View {
			Button {
				// Filter and save
				self.filterAndSaveModels()
				// Hide sheet
				self.isPresented.toggle()
			} label: {
				Text("Done")
			}
			.keyboardShortcut(.defaultAction)
		}
		
		/// Function to filter out blank model names
		private func filterAndSaveModels() {
			// Keep unique names
			self.customModelNames = Array(Set(self.customModelNames)).sorted()
			// Filter out blank model names
			self.customModelNames = self.customModelNames.filter { name in
				return !name.isEmpty
			}
			// Save
			InferenceSettings.customModelNames = self.customModelNames
		}
		
		struct CustomModelsEditorField: View {
			
			init(modelName: Binding<String>) {
				self._modelName = modelName
				self.name = modelName.wrappedValue
			}
			
			@Binding var modelName: String
			@State private var name: String
			@FocusState	private var isFocused: Bool
			
			var body: some View {
				TextField("", text: self.$name)
					.focused(self.$isFocused)
					.textFieldStyle(.plain)
					.onChange(of: isFocused) {
						if isFocused {
							name = modelName
						} else {
							modelName = name
						}
					}
					.onSubmit {
						modelName = name
					}
			}
			
		}
		
	}
	
}
