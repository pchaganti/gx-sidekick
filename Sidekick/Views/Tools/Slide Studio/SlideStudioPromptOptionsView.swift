//
//  SlideStudioPromptOptionsView.swift
//  Sidekick
//
//  Created by John Bean on 2/28/25.
//

import SwiftUI

struct SlideStudioPromptOptionsView: View {
	
	@EnvironmentObject private var slideStudioViewController: SlideStudioViewController
	
	@State private var slideCount: Float = 10.0
	
    var body: some View {
		HStack {
			ToggleWebSearchButton(
				useWebSearch: $slideStudioViewController.useWebSearch
			)
			Divider()
			slideSlider
		}
		.padding(.leading, 32)
		.padding(.bottom, 10)
		.frame(height: 25)
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
