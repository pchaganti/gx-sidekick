//
//  DetectorEntitySentencesView.swift
//  Sidekick
//
//  Created by John Bean on 2/25/25.
//

import SwiftUI

struct DetectorEntitySentencesView: View {
	
	@EnvironmentObject private var detectorViewController: DetectorViewController
	
	let isHuman: Bool
	
	var entityName: String {
		if self.isHuman {
			return String(localized: "human")
		}
		return "AI"
	}
	
	var color: Color {
		if self.isHuman {
			return .brightGreen
		}
		return .red
	}
	
	var chunks: [EvaluationDetails.Chunk] {
		guard let evaluationDetails = self.detectorViewController.evaluationDetails else {
			return []
		}
		return evaluationDetails.chunks.filter { chunk in
			if isHuman {
				return chunk.state == .drivingHumanProb
			}
			return chunk.state == .drivingAiProb
		}
	}
	
	var body: some View {
		Group {
			if !chunks.isEmpty {
				chunkList
			} else {
				EmptyView()
			}
		}
	}
	
	var chunkList: some View {
		VStack(
			alignment: .leading
		) {
			Text("Sentences driving \(entityName) probability:")
				.font(.headline)
			GroupBox {
				ForEach(
					self.chunks,
                    id: \.id
				) { chunk in
					HStack {
						RoundedRectangle(cornerRadius: 2.5)
							.fill(self.color.opacity(0.5))
							.frame(width: 5)
                        Text(
                            chunk.text
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                        )
							.font(.subheadline)
						Spacer()
					}
				}
				.padding(.horizontal, 5)
				.padding(.vertical, 4)
			}
		}
		.padding(.horizontal, 5)
	}
	
	}
