//
//  DetectorView.swift
//  Sidekick
//
//  Created by John Bean on 2/24/25.
//

import SwiftUI

struct DetectorView: View {
	
	@StateObject private var detectorViewController: DetectorViewController = .init()
	
	var body: some View {
		Group {
			switch detectorViewController.state {
				case .input:
					DetectorInputView()
				case .evaluating:
					evaluating
				case .result:
					DetectorEvaluationResultView()
			}
		}
		.inspector(
			isPresented: $detectorViewController.showInspector
		) {
			DetectorResultView()
		}
		.inspectorColumnWidth(
			min: 300,
			ideal: 350,
			max: 400
		)
		.interactiveDismissDisabled()
		.toolbar {
			ToolbarItemGroup(
				placement: .primaryAction
			) {
				exitButton
			}
		}
		.environmentObject(detectorViewController)
	}
	
	var evaluating: some View {
		ScrollView {
			HStack {
				Text(detectorViewController.text)
					.font(.title3)
				Spacer()
			}
			.padding()
		}
	}
	
	var exitButton: some View {
		Button {
			self.detectorViewController.reset()
		} label: {
			Text("Done")
		}
	}
	
}
