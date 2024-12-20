//
//  PromptAnalyzer.swift
//  Sidekick
//
//  Created by John Bean on 12/19/24.
//

import Foundation
import ImagePlayground
import CoreML
import NaturalLanguage

public class PromptAnalyzer {
	
	/// Function to detect what results are expected by the prompt
	public static func analyzePrompt(
		_ prompt: String
	) -> ResultType {
		// Check what types are available
		let resultTypes: [ResultType] = ResultType.allCases.filter(\.isAvailable)
		// If only one type is available, return it
		if resultTypes.count == 1 {
			return resultTypes.first!
		}
		// Else, init classifier model
		let mlModelConfig: MLModelConfiguration = MLModelConfiguration()
		mlModelConfig.computeUnits = .all
		guard let promptClassifier: NLModel = try? NLModel(
			mlModel: MLModel(
				contentsOf: Bundle.main.url(
					forResource: "UserRequestClassifier",
					withExtension: "mlmodelc"
				)!
			)
		) else {
			return .text
		}
		// Pre-process prompt to drop all trailing punctuation and convert to lowercase
		let processedPrompt: String = prompt.trimmingCharacters(
			in: .punctuationCharacters
		).lowercased()
		print("processedPrompt: \(processedPrompt)")
		// Run classifier
		guard let label: String = promptClassifier.predictedLabel(
			for: processedPrompt
		) else {
			return .text
		}
		// Return result type
		print("label: \(label)")
		return ResultType(label) ?? .text
	}
	
	/// The expected result type of a prompt
	public enum ResultType: String, CaseIterable {
		
		init?(
			_ rawValue: String
		) {
			if let resultType: ResultType = Self.allCases.filter({ type in
				type.rawValue == rawValue
			}).first {
				self = resultType
			} else {
				return nil
			}
		}
		
		case text = "text-generation"
		case image = "image-generation"
		
		/// A `Bool` value indicating whether the result type is available
		public var isAvailable: Bool {
			switch self {
				case .text:
					return true
				case .image:
					// Check if Image Playground functionality is available
					if #available(macOS 15.2, *) {
						return ImagePlaygroundViewController.isAvailable
					} else {
						return false
					}
			}
		}
		
	}
	
}
