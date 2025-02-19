//
//  ModelExplorerViewController.swift
//  Sidekick
//
//  Created by John Bean on 2/18/25.
//

import DefaultModels
import Foundation

public class ModelExplorerViewController: ObservableObject {
	
	/// An array of model families, of type ``ModelFamily``
	@Published public var modelFamilies: [ModelFamily] = []
	
	/// The current selected model family, of type `ModelFamily`
	@Published public var selectedFamily: ModelFamily? = nil
	
	/// A list of models from the selected family, of type `[HuggingFaceModel]`
	var selectedFamilyModels: [HuggingFaceModel] {
		return self.selectedFamily?.models ?? []
	}
	
	/// Function to load model families
	@MainActor
	public func loadModelFamilies() async {
		// Get all models
		let models: [HuggingFaceModel] = await DefaultModels
			.models
			.sorted(by: \.name)
			.sorted(by: \.params)
			.sorted(by: \.modelFamily.rawValue)
		// Extract list of families
		let families: [HuggingFaceModel.ModelFamily] = Set(
			models.map(\.modelFamily)
		).sorted(by: \.rawValue)
		// Group by ModelFamily
		var newModelFamilies: [ModelFamily] = []
		for family in families {
			let modelsInFamily: [HuggingFaceModel] = models
				.filter { model in
					return model.modelFamily == family
				}
			let newModelFamily: ModelFamily = ModelFamily(
				name: family.rawValue,
				family: modelsInFamily.first!.modelFamily,
				models: modelsInFamily
			)
			newModelFamilies.append(newModelFamily)
		}
		self.modelFamilies = newModelFamilies.sorted(by: \.name)
	}
	
}
