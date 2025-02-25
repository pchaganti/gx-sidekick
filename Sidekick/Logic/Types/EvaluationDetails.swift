//
//  EvaluationDetails.swift
//  Sidekick
//
//  Created by John Bean on 2/25/25.
//

import Foundation
import SwiftUI

public struct EvaluationDetails {
	
	var chunks: [Chunk] = []
	
	public struct Chunk: Identifiable {
		
		public var id: UUID = UUID()
		var text: String = ""
		
		var state: State = .normal
		
		public enum State: String, CaseIterable {
			
			case normal
			case drivingAiProb
			case drivingHumanProb
			
			/// The color in which the analysis results are displayed
			var highlightColor: Color {
				switch self {
					case .normal:
						return .primary.opacity(0.5)
					case .drivingAiProb:
						return .red
					case .drivingHumanProb:
						return .brightGreen
				}
			}
			
		}
		
	}
	
}
