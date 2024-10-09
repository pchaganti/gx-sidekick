//
//  Extension+Template.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import LLM

extension Template {
	
	public static func llama3(systemPrompt: String) -> Template {
		return Template(
			prefix: "<|begin_of_text|>",
			system: ("<|start_header_id|>system<|end_header_id|>\n", "\n<|eot_id|><|start_header_id|>user<|end_header_id|>"),
			user: ("", "\n<|eot_id|><|start_header_id|>assistant<|end_header_id|>"),
			bot: ("", "\n<|eot_id|><|start_header_id|>user<|end_header_id|>"),
			stopSequence: "<|eot_id|>",
			systemPrompt: systemPrompt,
			shouldDropLast: true
		)
	}
	
}
