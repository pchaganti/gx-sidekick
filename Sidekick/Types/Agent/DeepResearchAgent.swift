//
//  DeepResearchAgent.swift
//  Sidekick
//
//  Created by John Bean on 5/8/25.
//

import Foundation
import OSLog
import SimilaritySearchKit
import SwiftUI

public class DeepResearchAgent: Agent {
    
    /// A `Logger` object for the ``DeepResearchAgent`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DeepResearchAgent.self)
    )
    
    public init(
        messages: [Message],
        similarityIndex: SimilarityIndex?
    ) {
        self.messages = messages
        self.similarityIndex = similarityIndex
        self.startTime = .now
        self.currentStep = Step.allCases.first!
        self.sections = []
    }
    
    /// A `String` containing the name of the agent
    public let name: String = String(localized: "Deep Research")
    
    /// A `String` for all previous messages
    var messages: [Message]
    
    /// The ``SimilarityIndex`` from the selected ``Expert``
    var similarityIndex: SimilarityIndex?
    
    /// A `Date` for the starting time
    let startTime: Date
    
    /// The prompt extracted from the user's messages
    var prompt: String = ""
    /// The sections planned for the finished research report
    var sections: [Section] = []
    
    /// The current `Step` in the research process
    var currentStep: Step = Step.allCases.first!
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
            DeepResearchPreviewView(
                startTime: self.startTime,
                currentStep: self.currentStep,
                progress: self.progress,
                sections: self.sections
            )
        )
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
        try await self.researchAllSections()
        self.currentStep.nextCase()
        // Rewrite into draft report
        var draftResponse: LlamaServer.CompleteResponse? = nil
        for _ in 0..<3 { // Try for max 3 attempts
            if draftResponse == nil {
                draftResponse = try? await self.writeDraft()
            }
        }
        self.currentStep.nextCase()
        // Create diagrams if needed
        let diagrams: [Diagram] = try await self.createDiagrams()
        self.currentStep.nextCase()
        // Return final report
        var finalResponse: LlamaServer.CompleteResponse? = nil
        for _ in 0..<3 { // Try for max 3 attempts
            if finalResponse == nil {
                finalResponse = try? await self.finalizeReport(
                    diagrams: diagrams
                )
            }
        }
        // Switch back state and return
        await Model.shared.setStatus(.ready)
        if let finalResponse {
            return finalResponse
        } else {
            throw DeepResearchError.failedToDraftReport
        }
    }
    
    /// Function to check if enough information was given
    private func haveSufficientInformation() async -> Bool {
        // Formulate prompt
        let checkPrompt: String = """
You are about to start a multi-step research process on the user's query above.

Have you been given enough information to conduct further research on the user's query?
Do you need extra context to better conduct research on the user's query?
Do you need the user to clarify the requirements to better conduct research on the user's query?

Respond with YES if ALL 3 criteria above have been met. Alternatively, if the user has already responded to a set of follow up questions, or if they have declined a request for clarification, respond with YES. Else, respond with NO.

Respond with YES or NO only.
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
            useReasoning: true,
            showPreview: true
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
A user has provided the query below. Go through this query, extract insights and think about user intent, then create a step by step plan for how you would solve such a problem, where each "step" corresponds to a section in the final research report. Number each step in your plan. Think about how each section of the report interacts with other sections in a logical way.

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
      "isSearchNeeded": {
          "type": "bool", 
          "description": "Whether research on the web and other sources is useful for writing this section of the research report."
      },
      "required": [
        "title",
        "description", 
        "isSearchNeeded"
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
    
    /// Function to conduct research for all sections
    private func researchAllSections() async throws {
        // Try for maximum of 3 times
        for _ in 0..<3 {
            for index in self.sections.indices {
                // Get section
                let section: Section = self.sections[index]
                // If should research and no results
                if section.isSearchNeeded && section.results.isNilOrEmpty {
                    if let sectionResult: Section = try? await self.researchSection(
                        section: section
                    ) {
                        self.sections[index] = sectionResult
                    }
                }
            }
        }
    }
    
    /// Function to conduct research for a section of the report
    private func researchSection(
        section: Section
    ) async throws -> Section {
        let keyFindings: String = self.sections.map(
            keyPath: \.keyFinding
        ).compactMap({ $0 }).joined(separator: "\n")
        let researchPrompt: Message = Message(
            text: """
You are researching information for a section of a research report. This was the user's instruction regarding the overall report.

```user_instruction
\(self.prompt)
```

Here are the notes you made on this section.

```section_notes
\(section.getPromptDescription())
```

Here are prior key findings for earlier sections of the report.

```key_findings
\(keyFindings)
```

Call tools in a loop, reading and researching in websites and vector databases, until you have 7-10 sources for this section of the report. Do not stop until AT LEAST 7 tool calls are made.

When research is complete, respond with a list of relevant useful sources in the format below:

Source: URL or filepath
Description: A 4-5 sentence synopsis of information extracted from the source helpful for writing the research report section.

Respond with the list of sources only.
""",
            sender: .user
        )
        // Indicate started Deep Research
        await Model.shared.indicateStartedDeepResearch()
        // Get response
        let researchResponse: String = try await Model.shared.listenThinkRespond(
            messages: [researchPrompt],
            modelType: .regular,
            mode: .agent,
            useFunctions: true,
            functions: DeepResearchFunctions.functions
        ).text.reasoningRemoved
        // Copy section
        var section: Section = section
        // Convert to JSON
        let jsonPrompt: String = """
```
\(researchResponse)
```

Now, convert the sources above for each section in the research report into JSON.

Respond with an array of JSON objects, where each object corresponds to a source. Follow the JSON schema below.

{
  "type": "array",
  "items": [
        {
          "type": "object",
            "properties": {
                "url": {
                    "type": "string",
                    "format": "uri",
                    "description": "The URL associated with the source"
                },
                "text": {
                    "type": "string",
                    "description": "The text content of the source"
                }
            },
            "required": [
                "url", 
                "text"
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
        // Check with model for a maximum of 3 tries
        for _ in 0..<3 {
            do {
                // Get response
                let jsonResponse = try await Model.shared.listenThinkRespond(
                    messages: [jsonMessage],
                    modelType: .regular,
                    mode: .agent,
                    useReasoning: true,
                    useFunctions: false
                )
                let responseText: String = jsonResponse.text.reasoningRemoved
                // Decode response
                let decoder: JSONDecoder = JSONDecoder()
                let results: [Section.Result] = try decoder.decode(
                    [Section.Result].self,
                    from: responseText.data(using: .utf8)!
                )
                // Check if empty
                if results.isEmpty {
                    throw ResultDecodeError.isEmpty
                }
                section.results = results
                enum ResultDecodeError: Error {
                    case isEmpty
                }
            } catch {
                // Try again
                Self.logger.warning("DeepResearch: Failed to parse sections research JSON. Retrying...")
                continue
            }
        }
        // Summarize findings into 1 line
        let summarizePrompt: String = """
You are researching information for a section of a research report. This was the user's instruction regarding the overall report.

```user_instruction
\(self.prompt)
```

Here are the notes you made on this section.

```section_notes
\(section.getPromptDescription())
```

Here are the sites and content you found on the web.

```section_research
\(researchResponse)
```

Synthesize and summarize key findings from the research above, and write it into 2-3 sentences.

Respond with the key findings ONLY.
"""
        let summarizeMessage: Message = Message(
            text: summarizePrompt,
            sender: .user
        )
        // Get response
        let summarizeResponse = try await Model.shared.listenThinkRespond(
            messages: [jsonMessage],
            modelType: .regular,
            mode: .agent,
            useReasoning: true,
            useFunctions: false
        )
        section.keyFinding = summarizeResponse.text.reasoningRemoved
        return section
    }
    
    /// Function to create a first draft
    private func writeDraft() async throws -> LlamaServer.CompleteResponse {
        // Formulate prompt
        let sectionDescriptions: [String] = self.sections.enumerated().map { (index, section) in
            return """
```section_\(index + 1)_description
\(section.getPromptDescription(sectionNumber: index + 1))
```
"""
        }
        let draftPrompt: String = """
You are about to write a research report based on this user's query.

```user_query
\(self.prompt)
```

In previous interections, you split the report into \(self.sections.count) section, and conducted research on each of the sections. Below are titles, description and research results for each section.

\(sectionDescriptions.joined(separator: "\n\n"))

Now, write the report, citing sources in Markdown links.
"""
        let draftMessage: Message = Message(
            text: draftPrompt,
            sender: .user
        )
        // Add to messages
        self.messages = [draftMessage]
        // Get response
        let response = try await Model.shared.listenThinkRespond(
            messages: self.messages,
            modelType: .regular,
            mode: .`default`,
            useReasoning: true
        )
        // Add response to messages
        let draftResponse: Message = Message(
            text: response.text,
            sender: .assistant
        )
        self.messages.append(draftResponse)
        // Return
        return response
    }
    
    /// Function to create diagrams
    private func createDiagrams() async throws -> [Diagram] {
        // Formulate prompt
        var messages: [Message] = self.messages
        let listDiagramsPrompt: String = """
Read the research report above, and determine if and where diagrams should be added to the report. 

Respond with a list (or an empty) list of ideas for 0-5 diagrams that should be added, where each diagram has a filename and description. The description should include any data and figures needed for the chart.

Examples:

Filename: literature_genres
Description: A mindmap showing different genres of world literature, including Ancient, Classical and Modern Literature.

Filename: scientific_method
Description: A left-to-right flowchart showing the steps in the scientific method.

Filename: headphone market share
Description: A pie chart showing the market share of major headphone brands by revenue, with Apple at 40%, Samsung at 30%, Sony at 20% and other players making up the remaining 10% of the market. 
"""
        let listDiagramsMessage: Message = Message(
            text: listDiagramsPrompt,
            sender: .user
        )
        // Add to messages
        messages.append(listDiagramsMessage)
        // Get response
        let listDiagramsResponse = try await Model.shared.listenThinkRespond(
            messages: messages,
            modelType: .regular,
            mode: .`default`,
            useReasoning: true,
            showPreview: true
        )
        // Append to messages
        let listDiagramsResponseMessage: Message = Message(
            text: listDiagramsResponse.text,
            sender: .assistant
        )
        messages += [listDiagramsResponseMessage]
        // Prompt for data structure
        let jsonPrompt: String = """
Now, convert the plan above for each diagram into JSON.

Respond with an array of JSON objects, where each object corresponds to a section. Follow the JSON schema below.

{
  "type": "array",
  "items": [
    {
      "type": "object",
      "properties": {
        "filename": {
          "type": "string", 
          "description": "A short filename for this diagram."
        },
        "description": {
          "type": "string", 
          "description": "A brief, 1-3 sentence description of this diagram's topic and content. If needed for the diagram, this should include specific figures and data."
        }
      }
      "required": [
        "filename",
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
        var diagrams: [Diagram] = []
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
                // Decode response and exit loop
                let decoder: JSONDecoder = JSONDecoder()
                diagrams = try decoder.decode(
                    [Diagram].self,
                    from: responseText.data(using: .utf8)!
                )
                break
            } catch {
                // Try again
                Self.logger.warning("DeepResearch: Failed to parse report diagrams JSON. Retrying...")
                continue
            }
        }
        // Draw diagrams
        diagrams = try await diagrams.asyncMap { diagram in
            return try await self.createDiagram(diagram)
        }.compactMap({ $0 })
        // Return
        return diagrams
    }
    
    /// Function to create a diagram
    private func createDiagram(
        _ diagram: Diagram
    ) async throws -> Diagram? {
        // Formulate message
        let commandPrompt: String = self.getDiagramPrompt(
            prompt: diagram.description
        )
        let commandMessage: Message = Message(
            text: commandPrompt,
            sender: .user
        )
        var messages: [Message] = [commandMessage]
        var code: String = ""
        // Init attempts remaining
        var attemptsRemaining: Int = 4
        var responseText: String? = nil
        // Loop
        while attemptsRemaining >= 0 {
            do {
                let response = try await Model.shared.listenThinkRespond(
                    messages: messages,
                    modelType: .regular,
                    mode: .`default`
                )
                // On finish
                let fullResponse: String = response.text
                responseText = fullResponse
                // Remove markdown code tags and thinking process
                let mermaidCode: String = fullResponse.reasoningRemoved.replacingOccurrences(
                    of: "```mermaid",
                    with: ""
                ).replacingOccurrences(
                    of: "```",
                    with: ""
                ).replacingOccurrences(
                    of: "_",
                    with: " "
                ).trimmingWhitespaceAndNewlines()
                // Set the mermaid code
                code = mermaidCode
                try await self.render(
                    code: code,
                    attemptsRemaining: attemptsRemaining
                )
                // Check if SVG is valid, else, exit
                guard SVGValidator.validateSVG(
                    at: MermaidRenderer.previewFileUrl
                ) else {
                    return nil
                }
                // Move diagram
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                // Check if date can be extracted
                let dateStr = dateFormatter.string(from: Date.now)
                let name: String = diagram.filename.dropSuffixIfPresent(
                    ".svg"
                )
                let newUrl: URL = Settings
                    .containerUrl
                    .appendingPathComponent("Generated Images")
                    .appendingPathComponent("\(name)-\(dateStr).svg")
                await FileManager.copyItem(
                    from: MermaidRenderer.previewFileUrl,
                    to: newUrl
                )
                var diagram: Diagram? = diagram
                diagram?.imageUrl = newUrl
                // Exit
                return diagram
            } catch {
                // Try to get response text
                guard let responseText = responseText else {
                    return nil
                }
                let responseMessage: Message = Message(
                    text: responseText,
                    sender: .assistant
                )
                messages.append(responseMessage)
                // Try again with error message
                let errorText: String = """
The following error output was returned when rendering the diagram:

\(error.localizedDescription)

Fix the error. Respond with ONLY the corrected Mermaid code.
"""
                let iterateMessage: Message = Message(
                    text: errorText,
                    sender: .user
                )
                messages.append(iterateMessage)
                // Increment attempts
                attemptsRemaining -= 1
                // Log
                Self.logger.warning("Diagram render failed. Iterating with the error \"\(error.localizedDescription)\"")
            }
        }
        // Return nil if failed
        return nil
    }
    
    /// The full prompt used to generate mermaid diagram code, of type `String`
    func getDiagramPrompt(prompt: String) -> String {
        // Init prompt text
        let text: String = """
Use Mermaid markup language to draw a highly detailed diagram for the topic below. Respond with ONLY the Mermaid code.

\(prompt)
"""
        // Get cheatsheet text
        guard let cheatsheetURL: URL = Bundle.main.url(
            forResource: "mermaidCheatsheet",
            withExtension: "md"
        ) else {
            return prompt
        }
        let cheatsheetText: String = try! String(
            contentsOf: cheatsheetURL,
            encoding: .utf8
        )
        // Return full prompt
        return """
\(text)

Cheatsheet:

\(cheatsheetText)
"""
    }
    
    /// Function to render a diagram
    public func render(
        code: String,
        attemptsRemaining: Int = 3
    ) async throws {
        // Return if code is empty
        guard !code.isEmpty else {
            return
        }
        // Init renderer
        let renderer: MermaidRenderer = MermaidRenderer()
        // Save mermaid code
        MermaidRenderer.saveMermaidCode(code: code)
        // Render
        try await renderer.render(
            attemptsRemaining: attemptsRemaining
        )
    }
    
    /// Function to create a final draft
    private func finalizeReport(
        diagrams: [Diagram]
    ) async throws -> LlamaServer.CompleteResponse {
        // Formulate prompt
        var finalizePromptComponents: [String] = []
        let critique: String = "Critique, then improve the research report above, making it more coherent."
        let useSources: String = "Preserve all links and sources, while updating the numbering of sources as needed."
        finalizePromptComponents += [critique, useSources]
        // Add diagrams if needed
        if !diagrams.isEmpty {
            let diagramsDescription = diagrams.enumerated().map { (index, diagram) in
                if let url = diagram.imageUrl {
                    return """
Diagram \(index + 1):
Description: \(diagram.description)
Markdown Image: ![](\(url.path(percentEncoded: true)))
"""
                }
                return nil
            }.compactMap({ $0 }).joined(separator: "\n\n")
            let diagramsPrompt: String = """
These diagrams are available for the research report:

\(diagramsDescription)

Insert them into the report as Markdown images where neccessary, using percent encoding. (e.g. ![](/Users/\(NSUserName())/path/to/image/new%20diagram.svg). DO NOT precede the links with a schema such as "https://" or "file://".
"""
            finalizePromptComponents += [diagramsPrompt]
        }
        // Add format instruction
        let format: String = "Critique only in your reasoning process. Respond with the improved report ONLY."
        finalizePromptComponents.append(format)
        let finalizeMessage: Message = Message(
            text: finalizePromptComponents.joined(separator: "\n\n"),
            sender: .user
        )
        // Add to messages
        self.messages.append(finalizeMessage)
        // Get response
        let response = try await Model.shared.listenThinkRespond(
            messages: self.messages,
            modelType: .regular,
            mode: .`default`,
            useReasoning: true,
            showPreview: true
        )
        // Return
        return response
    }
    
    /// A enum for errors possible when conducting Deep Research
    public enum DeepResearchError: LocalizedError {
        
        case noInstructions
        case failedToExtractPrompt
        case failedToParseSections
        case failedToDraftReport
        
        public var errorDescription: String? {
            switch self {
                case .noInstructions:
                    return String(localized: "No prompt provided.")
                case .failedToExtractPrompt:
                    return String(localized: "Failed to extract prompt.")
                case .failedToParseSections:
                    return String(localized: "Failed to parse sections.")
                case .failedToDraftReport:
                    return String(localized: "Failed to draft report.")
            }
        }
        
    }
    
    /// A section in the research report
    public struct Section: Codable, Hashable {
        
        /// A `String` containing a title for this section
        var title: String
        /// A `String` containing a description for this section
        var description: String
        /// A `Bool` representing if external information is needed
        var isSearchNeeded: Bool
        /// A `String` containing any key findings
        var keyFinding: String? = nil
        /// An array of search results for the section
        var results: [Section.Result]? = nil
        
        /// Function the returns a `String` containing a description of this section to be used in prompting
        func getPromptDescription(
            sectionNumber: Int? = nil
        ) -> String {
            var components: [String] = []
            // Add numbering
            if let sectionNumber {
                let numbering: String = "Section \(sectionNumber):"
                components += [numbering]
            }
            // Add heading
            let heading: String = """
Title: \(self.title)
Description: \(self.description)
"""
            components += [heading]
            // Add content
            if let results = self.results, !results.isEmpty {
                components += ["Research Results:"]
                let sources: [String] = results.map { result in
                    return """
    Source: \(result.url)
    Content: \(result.text)
"""
                }
                components += sources
            }
            // Return prompt
            return components.joined(separator: "\n\n")
        }
        
        /// A research result for a section
        public struct Result: Codable, Hashable {
            
            var url: String
            var text: String
            
            var favicon: Favicon? {
                if let url: URL = URL(string: self.url) {
                    let favicon: Favicon = .init(url: url)
                    return favicon
                }
                return nil
            }
            
        }
        
    }
    
    public struct Diagram: Codable, Hashable {
        
        var filename: String
        var description: String
        
        var imageUrl: URL? = nil
        
    }
    
    /// The steps in the Deep Research process
    public enum Step: String, CaseIterable {
        
        case checkSufficientInformation
        case analyzePrompt
        case splitSections
        case prepareSections
        case firstDraft
        case createDiagrams
        case finalizeReport
        
        var localizedDescription: String {
            switch self {
                case .checkSufficientInformation:
                    return String(localized: "Check information")
                case .analyzePrompt:
                    return String(localized: "Analyze the request")
                case .splitSections:
                    return String(localized: "Divide into sections")
                case .prepareSections:
                    return String(localized: "Research each section")
                case .firstDraft:
                    return String(localized: "Write initial draft")
                case .createDiagrams:
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
    
}

