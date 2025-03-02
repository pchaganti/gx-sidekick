//
//  SlideStudioProgressView.swift
//  Sidekick
//
//  Created by John Bean on 2/28/25.
//

import SwiftfulLoadingIndicators
import SwiftUI

struct SlideStudioProgressView: View {
	
	@EnvironmentObject private var slideStudioViewController: SlideStudioViewController
	
    var body: some View {
		VStack(
			spacing: 35
		) {
			LoadingIndicator(
				animation: .fiveLinesWave,
				size: .large
			)
			stallingPhrase
		}
    }
	
	var stallingPhrase: some View {
		Text(self.slideStudioViewController.currentStep.stallingPhrase)
			.font(.title)
			.bold()
			.contentTransition(.numericText())
	}
	
}
