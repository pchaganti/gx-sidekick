//
//  DeepResearchAgent.swift
//  Sidekick
//
//  Created by John Bean on 5/8/25.
//

import Foundation
import OSLog
import SwiftUI

public class DeepResearchAgent: Agent {
    
    /// A `Logger` object for the ``DeepResearchAgent`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DeepResearchAgent.self)
    )
    
    public init(
        messages: [Message]
    ) {
        self.messages = messages
        self.startTime = .now
    }
    
    /// A `String` containing the name of the agent
    public let name: String = String(localized: "Deep Research")
    
    /// A `String` for all previous messages
    var messages: [Message]
    
    /// A `Date` for the starting time
    let startTime: Date
    
    /// The prompt extracted from the user's messages
    var prompt: String = ""
    /// The sections planned for the finished research report
    var sections: [Section] = []
    
    /// The current `Step` in the research process
    @Published var currentStep: Step = Step.allCases.first!
    /// A `Float` representing the progress so far
    var progress: Float {
        guard let index = Step.allCases.firstIndex(of: currentStep) else {
            return 0.0
        }
        let total = Step.allCases.count
        // Progress is the current step index + 1 divided by total steps
        return Float(index) / Float(total)
    }
    
    /// A `View` to visualize the agent's progress
    public var preview: AnyView {
        AnyView(
            MessageWrapperView(
                time: self.startTime,
                sender: .assistant
            ) {
                GroupBox {
                    HStack {
                        self.stepChain
                            .padding(.vertical, 8)
                        Divider()
                        Text("Blah")
                            .padding(.vertical, 8)
                            .frame(width: 350)
                    }
                    .padding(.horizontal, 8)
                }
            }
        )
    }
    
    /// A `View` for all steps in the agent
    public var stepChain: some View {
        VStack(
            alignment: .leading
        ) {
            Label(
                "Progress: \(String(format: "%.1f%%", progress * 100))",
                systemImage: "magnifyingglass"
            )
            .bold()
            .font(.title3)
            .contentTransition(.numericText(value: Double(progress)))
            ScrollView(
                .vertical,
                showsIndicators: false
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    ForEach(
                        Step.allCases,
                        id: \.self
                    ) { step in
                        StepChainLinkView(
                            currentStep: self.currentStep,
                            step: step
                        )
                    }
                }
                .padding(.vertical, 8)
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
    
    /// Function to begin execution of the agentic loop
    public func run() async throws -> LlamaServer.CompleteResponse {
        // Check instructions
        guard let lastMessage = self.messages.last,
              lastMessage.getSender() == .user else {
            throw DeepResearchError.noInstructions
        }
        // Get clarification if needed
        let informationIsSufficient: Bool = await self.haveSufficientInformation()
        if !informationIsSufficient {
            // Switch status back to display clarifying process
            await Model.shared.setStatus(.ready)
            // Write clarifying questions
            if let response = await self.writeClarificationQuestions() {
                Self.logger.info("DeepResearchAgent: Did not have sufficient information, presenting clarification questions")
                // Return
                return response
            }
        }
        Self.logger.info("DeepResearchAgent: No clarification questions needed, proceeding with research")
        self.currentStep.nextCase()
        // Extract prompt
        guard let prompt: String = await self.extractPrompt() else {
            throw DeepResearchError.failedToExtractPrompt
        }
        self.prompt = prompt
        Self.logger.info("DeepResearchAgent: Extracted prompt: \(prompt)")
        self.currentStep.nextCase()
        // Get rid of messages
        self.messages.removeAll()
        // Split into sections
        self.sections = try await self.splitIntoSections()
        let sectionsDescription: String = self.sections.enumerated().map { (index, section) in
            return section.getPromptDescription(sectionNumber: index + 1)
        }.joined(separator: "\n\n")
        Self.logger.info("DeepResearchAgent: Extracted sections:\n\n\(sectionsDescription)")
        self.currentStep.nextCase()
        // Do research for each section
        
        self.currentStep.nextCase()
        // Rewrite into draft report
        
        self.currentStep.nextCase()
        // Add diagrams / images as needed
        
        self.currentStep.nextCase()
        // Return final report
        let modelName: String = await Model.shared.selectedModelName ?? ""
        let response = LlamaServer.CompleteResponse(
            text: "Done!",
            responseStartSeconds: 0,
            predictedPerSecond: 0,
            modelName: modelName,
            usedServer: true
        )
        // Switch back status and return
        await Model.shared.setStatus(.ready)
        return response
    }
    
    /// Function to check if enough information was given
    private func haveSufficientInformation() async -> Bool {
        // Formulate prompt
        let checkPrompt: String = """
You are about to start a multi-step research process on the user's query above.

Have you been given enough information to conduct further research on the user's query?
Do you need extra context to better conduct research on the user's query?
Do you need the user to clarify the requirements to better conduct research on the user's query?

Respond with YES if ALL 3 criteria above have been met. Respond with YES or NO only.
"""
        let message: Message = Message(
            text: checkPrompt,
            sender: .user
        )
        // Add to messages
        let messages: [Message] = self.messages + [message]
        // Check with model for a maximum of 3 tries
        for _ in 0..<3 {
            do {
                // Get response
                let response = try await Model.shared.listenThinkRespond(
                    messages: messages,
                    modelType: .regular,
                    mode: .`default`,
                    useReasoning: true
                )
                let responseText: String = response.text.reasoningRemoved
                // Validate response
                let possibleResponses: [String] = ["YES", "NO"]
                if possibleResponses.contains(responseText) {
                    return responseText == "YES"
                }
            } catch {
                // Try again
                continue
            }
        }
        // If fell through, return false
        return false
    }
    
    /// Function to write clarification questions
    private func writeClarificationQuestions() async -> LlamaServer.CompleteResponse? {
        // Formulate prompt
        let checkPrompt: String = """
You are about to start a multi-step research process on the user's query above, but you have determined that you have not been given enough information.

Ask the user for more information and context. Respond with the questions ONLY.
"""
        let message: Message = Message(
            text: checkPrompt,
            sender: .user
        )
        // Add to messages
        let messages: [Message] = self.messages + [message]
        // Get response
        let response = try? await Model.shared.listenThinkRespond(
            messages: messages,
            modelType: .regular,
            mode: .`default`,
            useReasoning: true
        )
        // Return
        return response
    }
    
    /// Function to extract a prompt from the previous messages
    private func extractPrompt() async -> String? {
        // Formulate prompt
        let extractPrompt: String = """
You are about to start a multi-step research process on the user's query above.

In preparation, synthesize the user's prompt from the messages above, combining the original prompt with any extra information and requirements from follow up messages. The final, synthesized prompt should be imperative in tone, providing clear requirements and context.

Respond with the prompt ONLY.
"""
        let message: Message = Message(
            text: extractPrompt,
            sender: .user
        )
        // Add to messages
        let messages: [Message] = self.messages + [message]
        // Get response
        let response = try? await Model.shared.listenThinkRespond(
            messages: messages,
            modelType: .regular,
            mode: .`default`,
            useReasoning: true
        )
        // Return
        return response?.text.reasoningRemoved
    }
    
    /// Function to extract a prompt from the previous messages
    private func splitIntoSections() async throws -> [Section] {
        // Formulate prompt
        let planPrompt: String = """
A user has provided the query below. Go through this query, extract insights and think about user intent, then create a step by step plan for how you would solve such a problem, where each "step" corresponds to a section in the final research report. Number each step in your plan.

DO NOT try to directly provide an answer. ONLY think and plan.

```user_query
\(self.prompt)
```
"""
        let planMessage: Message = Message(
            text: planPrompt,
            sender: .user
        )
        // Add to messages
        var messages: [Message] = self.messages + [planMessage]
        // Get response
        let planResponse = try await Model.shared.listenThinkRespond(
            messages: messages,
            modelType: .regular,
            mode: .`default`,
            useReasoning: true
        )
        // Append to messages
        let planResponseMessage: Message = Message(
            text: planResponse.text,
            sender: .assistant
        )
        messages += [planResponseMessage]
        // Prompt for data structure
        let jsonPrompt: String = """
Now, convert the plan above for each section in the research report into JSON.

Respond with an array of JSON objects, where each object corresponds to a section. Follow the JSON schema below.

{
  "type": "array",
  "items": [
    {
      "type": "object",
      "properties": {
        "title": {
          "type": "string", 
          "description": "The title of this section."
        },
        "description": {
          "type": "string", 
          "description": "A brief, 2-3 sentence, description of this section in the research report explaining its purpose and relevance. The description should summarize what the section covers and how it relates to other sections."
        }
      },
      "required": [
        "title",
        "description"
      ]
    }
  ]
}

Respond with the array of JSON objects ONLY.
"""
        let jsonMessage: Message = Message(
            text: jsonPrompt,
            sender: .user
        )
        // Add to messages
        messages += [jsonMessage]
        // Check with model for a maximum of 3 tries
        for _ in 0..<3 {
            do {
                // Get response
                let jsonResponse = try await Model.shared.listenThinkRespond(
                    messages: messages,
                    modelType: .regular,
                    mode: .`default`,
                    useReasoning: true
                )
                let responseText: String = jsonResponse.text.reasoningRemoved
                // Decode response
                let decoder: JSONDecoder = JSONDecoder()
                let sections: [Section] = try decoder.decode(
                    [Section].self,
                    from: responseText.data(using: .utf8)!
                )
                return sections
            } catch {
                // Try again
                Self.logger.warning("DeepResearch: Failed to parse report sections JSON. Retrying...")
                continue
            }
        }
        // If fell through, throw error
        throw DeepResearchError.failedToParseSections
    }
    
    /// A enum of errors possible when conducting Deep Research
    public enum DeepResearchError: LocalizedError {
        
        case noInstructions
        case failedToExtractPrompt
        case failedToParseSections
        
        public var errorDescription: String? {
            switch self {
                case .noInstructions:
                    return String(localized: "No prompt provided.")
                case .failedToExtractPrompt:
                    return String(localized: "Failed to extract prompt.")
                case .failedToParseSections:
                    return String(localized: "Failed to parse sections.")
            }
        }
        
    }
    
    /// A section in the research report
    public struct Section: Codable {
        
        /// A `String` containing a title for this section
        var title: String
        /// A `String` containing a description for this section
        var description: String
        /// A `Bool` representing if external information is needed
        var isSearchNeeded: Bool? = nil
        
        /// Function the returns a `String` containing a description of this section to be used in prompting
        func getPromptDescription(
            sectionNumber: Int
        ) -> String {
            return """
Section \(sectionNumber):
Title: \(self.title)
Description: \(self.description)
"""
        }
        
    }
    
    /// The steps in the Deep Research process
    public enum Step: String, CaseIterable {
        
        case checkSufficientInformation
        case analyzePrompt
        case splitSections
        case searchSections
        case firstDraft
        case generateDiagrams
        case finalizeReport
        
        var localizedDescription: String {
            switch self {
                case .checkSufficientInformation:
                    return String(localized: "Check information")
                case .analyzePrompt:
                    return String(localized: "Analyze the request")
                case .splitSections:
                    return String(localized: "Divide into sections")
                case .searchSections:
                    return String(localized: "Research each section")
                case .firstDraft:
                    return String(localized: "Write initial draft")
                case .generateDiagrams:
                    return String(localized: "Create diagrams")
                case .finalizeReport:
                    return String(localized: "Polish and finalize")
            }
        }
        
        /// Function to check if a given step is a completed step
        func isCompletedStep(_ step: Step) -> Bool {
            // Get all preceding steps
            var allSteps: [Step] = []
            for step in Step.allCases {
                if step == self {
                    break
                }
                allSteps.append(step)
            }
            // Check if is previous
            return allSteps.contains(step)
        }
        
    }
    
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
    
}

