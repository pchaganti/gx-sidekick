//
//  LLaMa3.swift
//  Sidekick
//
//  Created by Bean John on 11/3/24.
//

import Foundation

public class LLaMa3: ModelSet {
	
	/// An array of `LLaMa3` models, of type ``HuggingFaceModel``
	public static let models: [HuggingFaceModel] = [
		LLaMa3.llama_3pt1_8b
	]

	/// Static constant for the LLaMa 3.1 8B model
	private static let llama_3pt1_8b: HuggingFaceModel = HuggingFaceModel(
		urlString: "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q8_0.gguf",
		minRam: 24,
		minGpu: 18,
		mmluScore: 66.6
	)
	
}
