//
//  CapabilityView.swift
//  Sidekick
//
//  Created by John Bean on 2/18/25.
//

import DefaultModels
import SwiftUI

struct SpecialtyView: View {
	
	var specialty: HuggingFaceModel.Specializations
	
	var symbolName: String {
		if !HuggingFaceModel.Specializations.allCases.contains(specialty) {
			return "questionmark.circle.fill"
		}
		switch specialty {
			case .fineTuned:
				return "metronome"
			case .coding:
				return "keyboard"
			case .math:
				return "plus.forwardslash.minus"
			case .reasoning:
				return "brain.fill"
			case .imageInput:
				return "photo.stack.fill"
			case .fullyOpenSource:
				return "lock.open.fill"
		}
	}
	
	var symbolColor: Color {
		if !HuggingFaceModel.Specializations.allCases.contains(specialty) {
			return .white
		}
		switch specialty {
			case .fineTuned:
				return .teal
			case .coding:
				return .green
			case .math:
				return .yellow
			case .reasoning:
				return .pink
			case .imageInput:
				return .orange
			case .fullyOpenSource:
				return .white
		}
	}
	
    var body: some View {
		Label(specialty.rawValue) {
			Image(systemName: symbolName)
				.foregroundStyle(symbolColor)
		}
		.padding(8)
		.background {
			RoundedRectangle(cornerRadius: 7)
				.fill(Color.secondary.opacity(0.15))
				.frame(minHeight: 25)
		}
    }
	
}
