//
//  InferenceSettingsView.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import FSKit_macOS
import SwiftUI
import UniformTypeIdentifiers

struct InferenceSettingsView: View {
	
	@AppStorage("modelUrl") private var modelUrl: URL?
	@AppStorage("specularDecodingModelUrl") private var specularDecodingModelUrl: URL?
	
	@State private var isEditingSystemPrompt: Bool = false
	@State private var isSelectingModel: Bool = false
	@State private var isSelectingSpeculativeDecodingModel: Bool = false
	
	@State private var temperature: Double = InferenceSettings.temperature
	@State private var useGPUAcceleration: Bool = InferenceSettings.useGPUAcceleration
	@State private var useSpeculativeDecoding: Bool = InferenceSettings.useSpeculativeDecoding
	@State private var contextLength: Int = InferenceSettings.contextLength
	
	@State private var useServer: Bool = InferenceSettings.useServer
	@State private var serverEndpoint: String = InferenceSettings.endpoint
	
    var body: some View {
		Form {
			Section {
				model
				speculativeDecoding
			} header: {
				Text("Models")
			}
			Section {
				parameters
			} header: {
				Text("Parameters")
			}
			Section {
				server
			} header: {
				Text("Server")
			}
		}
		.formStyle(.grouped)
		.scrollIndicators(.never)
		.sheet(isPresented: $isEditingSystemPrompt) {
			SystemPromptEditor(
				isEditingSystemPrompt: $isEditingSystemPrompt
			)
			.frame(maxHeight: 700)
		}
    }
	
	var model: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Model: \(modelUrl?.lastPathComponent ?? String(localized: "No Model Selected"))")
					.font(.title3)
					.bold()
				Text("This is the default LLM used.")
					.font(.caption)
			}
			Spacer()
			Button {
				self.isSelectingModel.toggle()
			} label: {
				Text("Manage")
			}
		}
		.contextMenu {
			Button {
				guard let modelUrl: URL = Settings.modelUrl else { return }
				FileManager.showItemInFinder(url: modelUrl)
			} label: {
				Text("Show in Finder")
			}
		}
		.sheet(isPresented: $isSelectingModel) {
			ModelListView(
				isPresented: $isSelectingModel
			)
			.frame(minWidth: 450, maxHeight: 600)
		}
	}
	
	var speculativeDecoding: some View {
		Group {
			useSpeculativeDecodingToggle
			if useSpeculativeDecoding {
				speculativeDecodingModel
			}
		}
	}
	
	var useSpeculativeDecodingToggle: some View {
		HStack(
			alignment: .top
		) {
			VStack(
				alignment: .leading
			) {
				HStack {
					Text("Use Speculative Decoding")
						.font(.title3)
						.bold()
					StatusLabelView.beta
				}
				Text("Improve inference speed by running a second model in parallel with the main model. This may use more memory.")
					.font(.caption)
			}
			Spacer()
			Toggle(
				"",
				isOn: $useSpeculativeDecoding.animation(.linear)
			)
		}
		.onChange(of: useSpeculativeDecoding) {
			InferenceSettings.useSpeculativeDecoding = self.useSpeculativeDecoding
		}
		.onAppear {
			self.useSpeculativeDecoding = InferenceSettings.useSpeculativeDecoding
		}
	}
	
	var speculativeDecodingModel: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text(
	 "Speculative Decoding Model: \(specularDecodingModelUrl?.lastPathComponent ?? String(localized: "No Model Selected"))"
				)
				.font(.title3)
				.bold()
				Text("This is the model used for speculative decoding. It should be smaller than the main model.")
					.font(.caption)
			}
			Spacer()
			Button {
				self.isSelectingSpeculativeDecodingModel.toggle()
			} label: {
				Text("Manage")
			}
		}
		.contextMenu {
			Button {
				guard let modelUrl: URL = InferenceSettings.speculativeDecodingModelUrl else {
					return
				}
				FileManager.showItemInFinder(url: modelUrl)
			} label: {
				Text("Show in Finder")
			}
		}
		.sheet(isPresented: $isSelectingSpeculativeDecodingModel) {
			ModelListView(
				isPresented: $isSelectingSpeculativeDecodingModel,
				forSpeculativeDecoding: true
			)
			.frame(minWidth: 450, maxHeight: 600)
		}
	}
	
	var parameters: some View {
		Group {
			systemPromptEditor
			contextLengthEditor
			temperatureEditor
			useGPUAccelerationToggle
		}
	}
		
	var systemPromptEditor: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("System Prompt")
					.font(.title3)
					.bold()
			}
			Spacer()
			Button {
				self.isEditingSystemPrompt.toggle()
			} label: {
				Text("Customise")
			}
		}
	}
	
	var contextLengthEditor: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Context Length")
					.font(.title3)
					.bold()
				Text("Context length is the maximum amount of information it can take as input for a query. A larger context length allows an LLM to recall more information, at the cost of slower output and more memory usage.")
					.font(.caption)
			}
			Spacer()
			TextField(
				"",
				value: $contextLength,
				formatter: NumberFormatter()
			)
			.textFieldStyle(.plain)
		}
		.onChange(of: contextLength) {
			InferenceSettings.contextLength = self.contextLength
		}
	}
	
	var temperatureEditor: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Temperature")
					.font(.title3)
					.bold()
				Text("Temperature is a parameter that influences LLM output, determining whether it is more random and creative or more predictable. The lower the setting the more predictable the model acts.")
					.font(.caption)
			}
			.frame(minWidth: 250)
			Spacer()
			Slider(
				value: $temperature,
				in: 0...2,
				step: 0.1
			)
			.frame(minWidth: 280)
			.overlay(alignment: .leading) {
				Text(String(format: "%g", self.temperature))
					.font(.body)
					.foregroundStyle(.secondary)
					.padding(.leading, 100)
			}
		}
		.onChange(of: temperature) {
			InferenceSettings.temperature = self.temperature
		}
	}
	
	var useGPUAccelerationToggle: some View {
		VStack {
			HStack(
				alignment: .top
			) {
				VStack(
					alignment: .leading
				) {
					Text("Use GPU Acceleration")
						.font(.title3)
						.bold()
					Text("Controls whether the GPU is used for inference.")
						.font(.caption)
				}
				Spacer()
				Toggle("", isOn: $useGPUAcceleration)
			}
			.onChange(of: useGPUAcceleration) {
				InferenceSettings.useGPUAcceleration = self.useGPUAcceleration
			}
			PerformanceGaugeView()
		}
		.onAppear {
			self.useGPUAcceleration = InferenceSettings.useGPUAcceleration
		}
	}
	
	
	var server: some View {
		Group {
			useServerToggle
			if useServer {
				serverEndpointEditor
			}
		}
	}
	
	var useServerToggle: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Use Server")
					.font(.title3)
					.bold()
				Text("Controls whether a server is used for inference when it is available.")
					.font(.caption)
			}
			Spacer()
			Toggle(
				"",
				isOn: $useServer.animation(.linear)
			)
		}
		.onChange(of: useServer) {
			InferenceSettings.useServer = self.useServer
		}
		.onAppear {
			self.useServer = InferenceSettings.useServer
		}
	}
	
	var serverEndpointEditor: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Endpoint")
					.font(.title3)
					.bold()
				Text("The endpoint on the server used for inference. This endpoint must be accessible from this device, and provide an OpenAI compatible API. (e.g. http://localhost:8000, where http://localhost:8000/v1/chat/completions is accessible)\n\nTo ensure privacy and security of your data, host your own server.")
					.font(.caption)
			}
			Spacer()
			VStack(
				alignment: .trailing
			) {
				TextField("", text: $serverEndpoint)
					.textFieldStyle(.roundedBorder)
					.frame(maxWidth: 250)
				Button {
					InferenceSettings.endpoint = self.serverEndpoint.replacingSuffix(
						"/",
						with: ""
					)
				} label: {
					Text("Save")
				}
			}
		}
		.onAppear {
			self.serverEndpoint = InferenceSettings.endpoint
		}
	}
	
}

#Preview {
    InferenceSettingsView()
}
