//
//  DeepResearchPreviewView.swift
//  Sidekick
//
//  Created by John Bean on 5/9/25.
//

import SwiftUI

struct DeepResearchPreviewView: View {
    
    var startTime: Date
    
    var currentStep: DeepResearchAgent.Step
    var progress: Float
    
    var sections: [DeepResearchAgent.Section]
    
    var body: some View {
        MessageWrapperView(
            time: self.startTime,
            sender: .assistant
        ) {
            GroupBox {
                HStack(
                    alignment: .top
                ) {
                    self.stepChain
                        .padding(.bottom, 150)
                        .padding(.vertical, 8)
                    Divider()
                    self.details
                        .padding(.vertical, 8)
                        .frame(width: 400)
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    /// A `View` for all steps in the agent
    var stepChain: some View {
        StepChainView(
            startTime: self.startTime,
            currentStep: self.currentStep,
            progress: self.progress
        )
    }
    
    /// A `View` for execution details in the agent
    var details: some View {
        VStack(
            alignment: .leading
        ) {
            if !self.sections.isEmpty {
                sectionsList
            }
            ForEach(
                self.sections.filter({ $0.results != nil }),
                id: \.self
            ) { section in
                SectionResearchSectionView(section: section)
            }
        }
    }
    
    var sectionsList: some View {
        DisclosureGroup {
            HStack {
                VStack(
                    alignment: .leading
                ) {
                    ForEach(
                        enumerating: self.sections
                    ) { (index, section) in
                        Text("\(index + 1): \(section.title)")
                            .padding(.leading, 8)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 5)
        } label: {
            Text("Research Report Sections")
                .font(.headline)
                .bold()
        }
    }
    
    struct SectionResearchSectionView: View {
        
        var section: DeepResearchAgent.Section
        
        var results: [DeepResearchAgent.Section.Result] {
            return self.section.results ?? []
        }
        
        var body: some View {
            DisclosureGroup {
                HStack {
                    resultsPreview
                    Spacer()
                }
                .padding(.vertical, 5)
            } label: {
                Text("Researched Section \"\(section.title)\"")
                    .font(.headline)
                    .bold()
            }
        }
        
        var resultsPreview: some View {
            VStack(
                alignment: .leading
            ) {
                ForEach(
                    self.results,
                    id: \.self
                ) { result in
                    if let url: URL = URL(string: result.url) {
                        WebsiteRowView(url: url)
                            .padding(.leading, 8)
                    }
                }
            }
        }
        
    }
    
}
