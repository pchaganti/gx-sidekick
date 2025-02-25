//
//  DetectorResultView.swift
//  Sidekick
//
//  Created by John Bean on 2/24/25.
//

import SwiftUI

struct DetectorResultView: View {
	
	@EnvironmentObject private var detectorViewController: DetectorViewController
	
	var percentage: Int {
		return detectorViewController.aiScore ?? 0
	}
	
    var body: some View {
		Group {
			switch detectorViewController.state {
				case .input:
					EmptyView()
				case .evaluating:
					DetectorEvaluationView()
				case .result:
					result
			}
		}
		.transition(
			.asymmetric(
				insertion: .push(from: .top),
				removal: .move(edge: .bottom)
			)
		)
    }
	
	var result: some View {
		VStack(
			alignment: .leading,
			spacing: 20
		) {
			ZStack {
				Rectangle()
					.fill(.clear)
					.frame(height: 1)
				aiProbabilityIndicator
			}
			Divider()
			ScrollView {
				DetectorEntitySentencesView(
					isHuman: false
				)
				DetectorEntitySentencesView(
					isHuman: true
				)
				.padding(.bottom, 7)
			}
			.scrollIndicators(.hidden)
		}
	}
	
	var aiProbabilityIndicator: some View {
		CircularProgressView(
			progress: Double(percentage) / 100.0,
			width: 15,
			fromColor: .brightGreen,
			toColor: .red
		)
		.frame(
			width: 150,
			height: 150
		)
		.overlay {
			VStack {
				Text("AI Probability")
				Text("\(percentage)%")
			}
			.font(.title2)
			.fontWeight(.heavy)
		}
		.padding(.top, 20)
	}
	
}
