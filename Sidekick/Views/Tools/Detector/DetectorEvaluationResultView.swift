//
//  DetectorEvaluationResultView.swift
//  Sidekick
//
//  Created by John Bean on 2/24/25.
//

import SwiftUI

struct DetectorEvaluationResultView: View {
	
	@EnvironmentObject private var detectorViewController: DetectorViewController
	
	var chunks: [EvaluationDetails.Chunk] {
		return self.detectorViewController.evaluationDetails?.chunks ?? [
			.init(
				text: self.detectorViewController.text,
				state: .normal
			)
		]
	}
	
    var body: some View {
		ScrollView {
			HStack {
				text
				Spacer()
			}
			.padding()
		}
		.toolbar {
			ToolbarItemGroup(
				placement: .primaryAction
			) {
				editButton
			}
		}
    }
	
	var text: some View {
        Group {
            ForEach(chunks) { chunk in
                Text(chunk.text)
                    .foregroundStyle(
                        chunk.state.highlightColor
                    )
            }
        }
        .font(.title3)
        .textSelection(.enabled)
	}
	
	var editButton: some View {
		Button {
			self.detectorViewController.reset(
				resetInput: false
			)
		} label: {
			Text("Edit")
		}
		.controlSize(.large)
	}
	
}
