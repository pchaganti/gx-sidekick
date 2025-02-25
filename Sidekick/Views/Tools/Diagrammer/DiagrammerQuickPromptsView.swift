//
//  DiagrammerQuickPromptsView.swift
//  Sidekick
//
//  Created by John Bean on 2/21/25.
//

import SwiftUI

struct DiagrammerQuickPromptsView: View {
	
	@EnvironmentObject private var diagrammerViewController: DiagrammerViewController
	
	let quickPrompts: [QuickPrompt] = [
		QuickPrompt(
			text: String(localized: "Draw a diagram of the eutrophication cycle and how it forms a positive feedback loop."),
			description: String(localized: "Eutrophication Cycle"),
			icon: "leaf.fill",
			color: Color.green
		),
		QuickPrompt(
			text: String(localized: "Generate a diagram modelling Florence's political system in the 15th century."),
			description: String(localized: "Florence's System"),
			icon: "hammer.fill",
			color: Color.brown
		),
		QuickPrompt(
			text: String(localized: "Generate a diagram illustrating the life cycle of salmon."),
			description: String(localized: "Salmon Life Cycle"),
			icon: "fish.fill",
			color: Color.orange
		),
		QuickPrompt(
			text: String(localized: "Generate a diagram illustrating how plastics are recycled."),
			description: String(localized: "Recycling"),
			icon: "arrow.3.trianglepath",
			color: Color.blue
		),
		QuickPrompt(
			text: String(localized: "Generate a diagram illustrating the process of photosynthesis."),
			description: String(localized: "Photosynthesis"),
			icon: "tree.fill",
			color: Color.green
		),
		QuickPrompt(
			text: String(localized: "Draw a diagram of the water cycle and its key components."),
			description: String(localized: "Water Cycle"),
			icon: "cloud.rain.fill",
			color: Color.white
		),
		QuickPrompt(
			text: String(localized: "Generate a diagram showing the structure and functions of a neuron."),
			description: String(localized: "Neuron Structure"),
			icon: "brain.fill",
			color: Color.pink
		),
		QuickPrompt(
			text: String(localized: "Generate a diagram illustrating the stages of mitosis."),
			description: String(localized: "Mitosis Stages"),
			icon: "figure.2.right.holdinghands",
			color: Color.white
		),
		QuickPrompt(
			text: String(localized: "Generate a diagram illustrating the process of plate tectonics."),
			description: String(localized: "Plate Tectonics"),
			icon: "mountain.2.fill",
			color: Color.gray
		),
		QuickPrompt(
			text: String(localized: "Draw a diagram of the human circulatory system."),
			description: String(localized: "Circulatory System"),
			icon: "heart.fill",
			color: Color.red
		)
	]
	
    var body: some View {
		ScrollView(
			.horizontal, showsIndicators: false
		) {
			prompts
		}
		.mask {
			Rectangle()
				.overlay(alignment: .leading) {
					ScrollMask(isLeading: true)
				}
				.overlay(alignment: .trailing) {
					ScrollMask(isLeading: false)
				}
		}
    }
	
	var prompts: some View {
		HStack {
			ForEach(self.quickPrompts) { prompt in
				QuickPromptButton(
					input: $diagrammerViewController.prompt,
					prompt: prompt
				)
			}
		}
		.padding(.horizontal, 20)
	}
	
}
