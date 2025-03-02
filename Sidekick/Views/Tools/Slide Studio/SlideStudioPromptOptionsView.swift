//
//  SlideStudioPromptOptionsView.swift
//  Sidekick
//
//  Created by John Bean on 2/28/25.
//

import SwiftUI

struct SlideStudioPromptOptionsView: View {
	
	@EnvironmentObject private var slideStudioViewController: SlideStudioViewController
	
	var webSearchTextColor: Color {
		return self.slideStudioViewController.useWebSearch ? .accentColor : .secondary
	}
	
	var webSearchBubbleColor: Color {
		return self.slideStudioViewController.useWebSearch ? .accentColor.opacity(0.4) : .clear
	}
	
	@State private var slideCount: Float = 10.0
	
    var body: some View {
		HStack {
			webSearchButton
			Divider()
			slideSlider
		}
		.padding(.leading, 32)
		.padding(.bottom, 10)
		.frame(height: 25)
    }
	
	var webSearchButton: some View {
		Button {
			withAnimation(.linear) {
				self.slideStudioViewController.useWebSearch.toggle()
			}
		} label: {
			Label("Web Search", systemImage: "globe")
				.foregroundStyle(self.webSearchTextColor)
				.font(.caption)
				.padding(5)
				.background {
					Capsule()
						.fill(webSearchBubbleColor)
				}
		}
		.buttonStyle(.plain)
	}
	
	var slideSlider: some View {
		HStack {
			Text("Slides: \(self.slideStudioViewController.pageCount)")
				.font(.caption)
				.foregroundStyle(.secondary)
				.contentTransition(
					.numericText(
						value: Double(self.slideStudioViewController.pageCount)
					)
				)
			Slider(
				value: self.$slideCount.animation(.linear),
				in: 3...20
			)
			.frame(maxWidth: 200)
			.scaleEffect(0.75, anchor: .center)
			.onChange(of: self.slideCount) {
				withAnimation(.linear) {
					self.slideStudioViewController.pageCount = Int(self.slideCount)
				}
			}
			.offset(x: -20)
		}
	}
	
}
