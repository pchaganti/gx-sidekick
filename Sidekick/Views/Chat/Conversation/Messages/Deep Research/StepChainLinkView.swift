//
//  StepChainLinkView.swift
//  Sidekick
//
//  Created by John Bean on 5/9/25.
//

import SwiftUI

public struct StepChainLinkView: View {
    
    var currentStep: DeepResearchAgent.Step
    var step: DeepResearchAgent.Step
    
    var isComplete: Bool {
        return self.currentStep.isCompletedStep(step) && self.currentStep != step
    }
    
    var color: Color {
        if self.currentStep.isCompletedStep(step) {
            return .green
        } else if self.currentStep == step {
            return .yellow
        }
        return .gray
    }
    
    var gradient: LinearGradient {
        var colors: [Color] = [.gray]
        var lastStep = self.currentStep
        lastStep.prevCase()
        if lastStep == step && step != DeepResearchAgent.Step.allCases.last {
            colors = [.green, .green, .green, .yellow]
        } else if self.currentStep.isCompletedStep(step) {
            colors = [.green]
        } else if self.currentStep == step {
            colors = [.yellow, .yellow, .yellow, .gray]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var imageName: String {
        return !isComplete ? "circle.fill" : "checkmark.circle.fill"
    }
    
    var topRadius: CGFloat {
        let isFirstStep = step == DeepResearchAgent.Step.allCases.first
        return isFirstStep ? 4.5 / 2 : 0
    }
    
    var bottomRadius: CGFloat {
        let isLastStep = step == DeepResearchAgent.Step.allCases.last
        return isLastStep ? 4.5 / 2 : 0
    }
    
    var textColor: Color {
        if self.step == self.currentStep {
            return .primary.mix(with: .gray, by: 0.5)
        }
        return !isComplete ? .gray : .primary
    }
    
    public var body: some View {
        HStack(
            spacing: 14
        ) {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: topRadius,
                    bottomLeadingRadius: bottomRadius,
                    bottomTrailingRadius: bottomRadius,
                    topTrailingRadius: topRadius
                )
                .fill(self.gradient)
                .frame(width: 4.5, height: 50)
                Image(systemName: self.imageName)
                    .resizable()
                    .frame(width: 19, height: 19)
                    .foregroundStyle(color)
                    .background {
                        Circle()
                            .fill(.white)
                            .padding(3)
                    }
            }
            Text(step.localizedDescription)
                .font(.body)
                .bold()
                .foregroundStyle(textColor)
        }
    }
    
}
