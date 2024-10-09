//
//  Model.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import FSKit_macOS
import LLM

@MainActor
public class Model: LLM {
	
	convenience init(
		systemPrompt: String
	) {
		// Make sure bookmarks are loaded
		let _ = Bookmarks.shared
		// Get model
		var modelUrl: URL
		if Settings.modelUrl != nil {
			modelUrl = Settings.modelUrl!
		} else {
			let modelDir: URL = URL
				.applicationSupportDirectory
				.appendingPathComponent("Models")
			guard let firstModelUrl: URL = modelDir.contents?.first else {
				fatalError("Could not find model at \(modelDir)")
			}
			modelUrl = firstModelUrl
		}
		// Init
		let temp: Float = Float(InferenceSettings.temperature)
		let maxTokenCount: Int32 = Int32(InferenceSettings.contextLength)
		self.init(
			from: modelUrl,
			template: .llama3(systemPrompt: systemPrompt),
			temp: temp,
			historyLimit: 8,
			maxTokenCount: maxTokenCount
		)
	}
	
}
