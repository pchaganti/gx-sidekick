//
//  DefaultModels.swift
//  Sidekick
//
//  Created by Bean John on 11/3/24.
//

import Foundation

public class DefaultModels {
	
	/// An array of model families, conforming to ``ModelSet``
	private static let modelFamilies: [any ModelSet.Type] = [
		LLaMa3.self,
		Gemma2.self,
		Qwen2.self
	]
	
	/// All default models that can be run by the device, in an array of ``HuggingFaceModel``
	private static var defaultModels: [HuggingFaceModel] {
		let models: [HuggingFaceModel] = self.modelFamilies.map { family in
			family.models
		}.reduce([], +)
		return models
	}
	
	/// The reccomended model for the device, of type ``HuggingFaceModel``
	public static var recommendedModel: HuggingFaceModel {
		// Get baseline model
		let minModel: HuggingFaceModel = defaultModels.sorted(
			by: \.minRam
		).first!
		// Get top end model that can be run
		if let maxModel: HuggingFaceModel = defaultModels.filter({
			$0.canRun()
		}).sorted(
			by: \.mmluScore,
			order: .reverse
		).first {
			return maxModel
		} else {
			return minModel
		}
	}
	
	/// A function to get the recommended model for a particular spec
	/// - Parameters:
	///   - ramSize: The amount of RAM in the device, in type `Int`
	///   - gpuCoreCount: The number of GPU cores in the device, in type `Int`
	/// - Returns: The reccomended model for the device, in type ``HuggingFaceModel``
	private static func getReccomendedModelForSpecs(
		ramSize: Int,
		gpuCoreCount: Int
	) -> HuggingFaceModel {
		// Get baseline model
		let minModel: HuggingFaceModel = defaultModels.sorted(
			by: \.minRam
		).first!
		// Get top end model that can be run
		if let maxModel: HuggingFaceModel = defaultModels.filter({
			$0.canRun(
				unifiedMemorySize: ramSize,
				gpuCoreCount: gpuCoreCount
			)
		}).sorted(
			by: \.mmluScore,
			order: .reverse
		).first {
			return maxModel
		} else {
			return minModel
		}
	}
	
	/// A function to test model reccomendations
	public static func checkModelRecommendations() {
		// List configs for testing
		let configs: [
			(ramSize: Int, gpuCoreCount: Int)
		] = [
			(8, 7),
			(8, 8),
			(8, 10),
			(16, 8),
			(16, 10),
			(16, 19),
			(18, 16),
			(32, 19),
			(32, 30),
			(32, 38),
			(64, 38),
			(64, 40)
		]
		// Get reccomendations
		configs.forEach { ramSize, gpuCoreCount in
			let model: HuggingFaceModel = DefaultModels.getReccomendedModelForSpecs(
				ramSize: ramSize,
				gpuCoreCount: gpuCoreCount
			)
			print("A Mac with \(ramSize) GB of RAM and \(gpuCoreCount) GPU cores is recommended to use \(model.name).")
		}
	}
	
}
