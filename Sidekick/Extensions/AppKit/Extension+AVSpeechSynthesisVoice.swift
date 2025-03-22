//
//  Extension+AVSpeechSynthesisVoice.swift
//  Sidekick
//
//  Created by John Bean on 3/22/25.
//

import Foundation
import AVFoundation

extension AVSpeechSynthesisVoice {
	
	/// A `String` containg a formatted version of a voice's name
	var prettyName: String {
		let name = self.name
		if name.lowercased().contains("default") || name.lowercased().contains("premium") || name.lowercased().contains("enhanced") {
			return name
		}
		let qualityString = {
			switch self.quality.rawValue {
				case 1: return "Default"
				case 2: return "Enhanced"
				case 3: return "Premium"
				default: return "Unknown"
			}
		}()
		return "\(name) (\(qualityString))"
	}
}
