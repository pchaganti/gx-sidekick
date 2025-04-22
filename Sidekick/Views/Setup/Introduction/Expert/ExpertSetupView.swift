//
//  ExpertSetupView.swift
//  Sidekick
//
//  Created by John Bean on 4/22/25.
//

import MarkdownUI
import SwiftUI

struct ExpertSetupView: View {
    
    @State private var step: Step = .intro
    @State private var expert: Expert = Expert(
        name: "Tutorial",
        symbolName: "bubble.left.and.text.bubble.right.fill.rtl",
        color: Color.tutorialExpert,
        useWebSearch: false
    )
    @State private var systemPrompt: String = InferenceSettings.systemPrompt
    
    @EnvironmentObject private var introductionViewController: IntroductionViewController
    @EnvironmentObject private var lengthyTasksController: LengthyTasksController
    @EnvironmentObject private var expertManager: ExpertManager
    
    let introText: String = String(localized: """
### Experts are the primary way Sidekick taps into domain specific knowledge and gains context about you and your work. 

### Let's create an tutorial expert so you can learn about Sidekick!
""")
    
    var isUpdating: Bool {
        let taskName: String = String(
            localized: "Updating resource index for expert \"\(self.expert.name)\""
        )
        return lengthyTasksController.tasks
            .map(\.name)
            .contains(
                taskName
            )
    }
    
    var hasResources: Bool {
        return !self.expert.resources.resources.isEmpty
    }
    
    var body: some View {
        Group {
            switch self.step {
                case .intro:
                    intro
                case .selectResource, .writeSystemPrompt:
                    expertEditor
                case .done:
                    done
            }
        }
    }
    
    var intro: some View {
        VStack {
            Markdown(introText)
                .frame(minWidth: 450)
            next
        }
    }
    
    var expertEditor: some View {
        VStack {
            if self.step == .selectResource {
                Label(
                    "Click \"Add\", select \"File / Folder\", then click \"Open\" to add files.",
                    systemImage: "arrow.down"
                )
                .font(.title2)
                .bold()
                .padding(.horizontal)
            }
            Form {
                ResourceSectionView(
                    expert: self.$expert,
                    isTutorial: true,
                    fileUrl: Bundle.main.url(
                        forResource: "Markdown",
                        withExtension: ""
                    )!
                )
                .disabled(self.step == .writeSystemPrompt)
                if self.step == .writeSystemPrompt {
                    systemPromptEditor
                }
            }
            .formStyle(.grouped)
            if self.step == .writeSystemPrompt {
                Label(
                    "Configure the system prompt to customize the expert's behaviour",
                    systemImage: "arrow.up"
                )
                .font(.title2)
                .bold()
                .padding(.horizontal)
            }
            next
                .disabled(self.isUpdating || !self.hasResources)
        }
    }
    
    var systemPromptEditor: some View {
        Section {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("System Prompt")
                        .font(.title3)
                        .bold()
                    Text("This expert's system prompt")
                        .font(.caption)
                    Button {
                        systemPrompt = InferenceSettings.systemPrompt
                    } label: {
                        Text("Use Default")
                    }
                }
                Spacer()
                TextEditor(text: $systemPrompt)
                    .font(.title2)
                    .onChange(
                        of: systemPrompt
                    ) {
                        self.saveSystemPrompt()
                    }
            }
        } header: {
            Text("System Prompt")
        }
    }
    
    var done: some View {
        VStack {
            Markdown("### The tutorial expert is ready! When setup is complete, select it in the toolbar, and ask it questions about Sidekick.")
            HStack {
                Spacer()
                Button {
                    // Add expert
                    self.expertManager.add(expert)
                    // Switch to next page
                    self.introductionViewController.page.nextCase()
                } label: {
                    Text("Next")
                }
                .controlSize(.large)
            }
        }
    }
    
    var next: some View {
        HStack {
            Spacer()
            Button {
                self.step.nextCase()
            } label: {
                Text("Next")
            }
            .controlSize(.large)
        }
    }
    
    public enum Step: CaseIterable {
        case intro
        case selectResource
        case writeSystemPrompt
        case done
    }
    
    private func saveSystemPrompt() {
        // Save system prompt changes
        if !systemPrompt.isEmpty {
            if systemPrompt == InferenceSettings.systemPrompt {
                self.expert.systemPrompt = nil
                return
            }
            self.expert.systemPrompt = systemPrompt
        }
    }
    
}
