//
//  SlideStudioQuickPromptsView.swift
//  Sidekick
//
//  Created by John Bean on 2/21/25.
//

import SwiftUI

struct SlideStudioQuickPromptsView: View {
	
	@EnvironmentObject private var slideStudioViewController: SlideStudioViewController
	
	let quickPrompts: [QuickPrompt] = [
		QuickPrompt(
			text: String(localized: "Create a presentation explaining the Von Neumann architecture."),
			description: String(localized: "Von Neumann Architecture"),
			icon: "cpu",
			color: Color.green
		),
		QuickPrompt(
			text: String(localized: "Generate a presentation introducing the Late Ming Dynasty and the transition to the Qing Dynasty."),
			description: String(localized: "End of the Ming Dynasty"),
			icon: "crown.fill",
			color: Color.yellow
		),
		QuickPrompt(
			text: String(localized: "Create a presentation explaining the principles of supply and demand."),
			description: String(localized: "Supply and Demand"),
			icon: "chart.line.uptrend.xyaxis",
			color: Color.purple
		),
		QuickPrompt(
			text: String(localized: "Generate a presentation about the irregular inter-annual cycle, ENSO."),
			description: String(localized: "ENSO Cycle"),
			icon: "globe.asia.australia.fill",
			color: Color.cyan
		),
		QuickPrompt(
			text: String(localized: "Generate a presentation about nucleic acids and how it carries our genetic code."),
			description: String(localized: "Nucleic Acids"),
			icon: "figure.and.child.holdinghands",
			color: Color.pink
		),
		QuickPrompt(
			text: String(localized: "Generate a presentation about the causes of the Renaissance."),
			description: String(localized: "Causes of the Renaissance"),
			icon: "music.note.list",
			color: Color.indigo
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
					input: $slideStudioViewController.prompt,
					prompt: prompt
				)
			}
		}
		.padding(.horizontal, 20)
	}
	
}
