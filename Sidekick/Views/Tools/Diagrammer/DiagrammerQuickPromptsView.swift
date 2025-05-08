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
            text: String(localized: "Show a pie chart of favorite foods among students in a classroom. Use hypothetical data."),
            description: String(localized: "Foods"),
            icon: "birthday.cake.fill",
            color: Color.mint
        ),
        QuickPrompt(
            text: String(localized: "Draw a diagram of the human circulatory system."),
            description: String(localized: "Circulatory System"),
            icon: "heart.fill",
            color: Color.red
        ),
        QuickPrompt(
            text: String(localized: "Create a mindmap showing different genres of world literature."),
            description: String(localized: "Genres"),
            icon: "book.fill",
            color: Color.orange
        ),
        QuickPrompt(
            text: String(localized: "Draw a diagram of the water cycle and its key components."),
            description: String(localized: "Water Cycle"),
            icon: "cloud.rain.fill",
            color: Color.white
        ),
        QuickPrompt(
            text: String(localized: "Draw a left-to-right flowchart showing the steps in the scientific method."),
            description: String(localized: "Scientific Method"),
            icon: "testtube.2",
            color: Color.cyan
        ),
        QuickPrompt(
            text: String(localized: "Model a binary tree representing animal classification (e.g., vertebrates and invertebrates)."),
            description: String(localized: "Animal Classification"),
            icon: "hare",
            color: Color.pink
        ),
        QuickPrompt(
            text: String(localized: "Show a line chart of average monthly temperatures in a city. Use hypothetical data."),
            description: String(localized: "Temperatures"),
            icon: "thermometer.transmission",
            color: Color.yellow
        ),
        QuickPrompt(
            text: String(localized: "Visualize a student's daily activities with a journey chart."),
            description: String(localized: "Timetable"),
            icon: "figure.walk",
            color: Color.white
        ),
        QuickPrompt(
            text: String(localized: "Create a kanban board for organizing household chores with 'Todo', 'In progress', and 'Done' columns."),
            description: String(localized: "Chores"),
            icon: "tablecells",
            color: Color.brightGreen
        ),
        QuickPrompt(
            text: String(localized: "Generate a diagram showing the structure and functions of a neuron."),
            description: String(localized: "Neuron"),
            icon: "brain.fill",
            color: Color.pink
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
                    ScrollMask(edge: .leading)
                }
                .overlay(alignment: .trailing) {
                    ScrollMask(edge: .trailing)
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
