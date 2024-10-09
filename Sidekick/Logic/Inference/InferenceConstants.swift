//
//  InferenceConstants.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import FSKit_macOS

public class InferenceConstants {
	
	public enum InferenceError: String, Error {
		case invalidFile = "Invalid file"
		case invalidDir = "Invalid directory"
		case noFilesInDir = "No files found in directory"
	}
	
	/// Static constant for the default LLM
	static let defaultModelUrl: URL = URL(
		string: "https://huggingface.co/bullerwins/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q6_K.gguf"
	)!
	
}
