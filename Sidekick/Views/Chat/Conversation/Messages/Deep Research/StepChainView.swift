//
//  StepChainView.swift
//  Sidekick
//
//  Created by John Bean on 5/9/25.
//

import SwiftUI

struct StepChainView: View {
    
    var startTime: Date
    
    var currentStep: DeepResearchAgent.Step
    var progress: Float
    
    var body: some View {
        VStack(
            alignment: .leading
        ) {
            // Show progress as percentage
            Label(
                "Progress: \(String(format: "%.0f%%", progress * 100))",
                systemImage: "magnifyingglass"
            )
            .bold()
            .font(.title3)
            .contentTransition(.numericText(value: Double(progress)))
            // Show timer
            Text(self.startTime, style: .timer)
            // Show steps in a chain
            self.steps
        }
    }
    
    var steps: some View {
        ScrollView(
            .vertical,
            showsIndicators: false
        ) {
            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                ForEach(
                    DeepResearchAgent.Step.allCases,
                    id: \.self
                ) { step in
                    StepChainLinkView(
                        currentStep: self.currentStep,
                        step: step
                    )
                }
            }
            .padding(.vertical, 12)
            .id(self.currentStep)
        }
        .mask {
            Rectangle()
                .overlay(alignment: .top) {
                    ScrollMask(edge: .top)
                }
                .overlay(alignment: .bottom) {
                    ScrollMask(edge: .bottom)
                }
        }
    }
    
}
