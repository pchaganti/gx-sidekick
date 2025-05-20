//
//  ChatParameters.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import Foundation
import OSLog
import SimilaritySearchKit

struct ChatParameters: Codable {
	
    /// A `Logger` object for the ``ChatParameters`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ChatParameters.self)
    )
    
	/// Init for non-chat
	init(
        modelType: ModelType,
        usingRemoteModel: Bool,
        systemPrompt: String,
        messages: [Message.MessageSubset]
	) async {
        // Add system prompt if needed
        if !messages.contains(where: { $0.role == .system }) {
            let systemPromptMsg: Message = Message(
                text: systemPrompt,
                sender: .system
            )
            let systemPromptMsgSubset: Message.MessageSubset = await Message.MessageSubset(
                usingRemoteModel: usingRemoteModel,
                message: systemPromptMsg,
                useReasoning: modelType == .regular
            )
            self.messages = [systemPromptMsgSubset] + messages
        } else {
            self.messages = messages
        }
		self.model = Self.getModelName(modelType: modelType) ?? ""
	}
	
	/// Init for chat & context aware agent
	init(
		modelType: ModelType,
        usingRemoteModel: Bool,
        systemPrompt: String,
        messages: [Message.MessageSubset],
        useWebSearch: Bool = false,
        useFunctions: Bool = false,
        functions: [AnyFunctionBox]? = nil
	) async {
		// Formulate messages
		// Formulate system prompt
		var fullSystemPromptComponents: [String] = []
		fullSystemPromptComponents.append(systemPrompt)
        // Get metadata about the user and the date
        fullSystemPromptComponents.append(InferenceSettings.metadataPrompt)
        // Get information about the user
        var prompt: String? = nil
        if let content = messages.last?.content {
            switch content {
                case .textOnly(let string):
                    prompt = string
                case .multimodal(let contents):
                    for content in contents {
                        switch content {
                            case .text(let string):
                                prompt = string
                            default:
                                continue
                        }
                    }
            }
        }
        if let prompt,
            let memorizedInfo = await InferenceSettings.getMemoryPrompt(
            prompt: prompt
        ) {
            fullSystemPromptComponents.append(memorizedInfo)
        }
        // Tell the LLM to use sources
        fullSystemPromptComponents.append(InferenceSettings.useSourcesPrompt)
        // Tell the LLM to use functions when enabled and server does not support native tool calling
        let functions: [any AnyFunctionBox] = functions ?? DefaultFunctions.chatFunctions
        if Settings.useFunctions && useFunctions {
            fullSystemPromptComponents.append(InferenceSettings.useFunctionsPrompt)
            // Inject function schema if no native tool calling or if using local model
            let canReachServer: Bool = await Model.shared.remoteServerIsReachable()
            let isUsingLocalModel: Bool = (!canReachServer || !InferenceSettings.useServer)
            if !InferenceSettings.hasNativeToolCalling || isUsingLocalModel {
                fullSystemPromptComponents.append(InferenceSettings.functionsSchemaPrompt)
                let functions: [any AnyFunctionBox] = functions
                for function in functions {
                    fullSystemPromptComponents.append(function.getJsonSchema())
                }
            }
        }
        // Join all components
		let fullSystemPrompt: String = fullSystemPromptComponents.joined(separator: "\n\n")
		// Formulate system prompt message
		let systemPromptMsg: Message = Message(
			text: fullSystemPrompt,
			sender: .system
		)
		let systemPromptMsgSubset: Message.MessageSubset = await Message.MessageSubset(
            usingRemoteModel: usingRemoteModel,
            message: systemPromptMsg,
            temporaryResources: [],
            shouldAddSources: false,
            useReasoning: modelType == .regular,
            useWebSearch: false
		)
		let messagesWithSystemPrompt: [Message.MessageSubset] = [systemPromptMsgSubset] + messages
		self.messages = messagesWithSystemPrompt
		self.model = Self.getModelName(modelType: modelType) ?? ""
        self.tools = !useFunctions ? [] : functions.map(keyPath: \.openAiFunctionCall)
	}
	
	var model: String
	var messages: [Message.MessageSubset]
    
    var tools: [OpenAIFunction] = []
    
	var temperature = InferenceSettings.temperature
	
	var stream: Bool = true
	var stream_options: StreamOptions = .init()
	
    /// Function to convert chat parameters to JSON
    public func toJSON(
        usingRemoteModel: Bool,
        modelType: ModelType,
        omittedParams: [ParamKey] = []
    ) -> String {
        // Omit tools if non-regular, or has no native tool calling
        var omittedParams = omittedParams
        if modelType != .regular || !InferenceSettings.hasNativeToolCalling || !usingRemoteModel {
            omittedParams.append(.tools)
        }
        // If is remote model, omit temperature to use provider reccomended params
        if usingRemoteModel {
            omittedParams.append(.temperature)
        }
        // Keep unique omits only
        omittedParams = Array(Set(omittedParams))
        // Use JSONEncoder and a wrapper struct for omitted keys
        struct OmitWrapper: Encodable {
            
            let model: String?
            let messages: [Message.MessageSubset]?
            let temperature: Double?
            let stream: Bool?
            let stream_options: StreamOptions?
            let tools: [OpenAIFunction]?
            
            init(
                from parent: ChatParameters,
                omitted: [ParamKey]
            ) {
                self.model = omitted.contains(.model) ? nil : parent.model
                self.messages = omitted.contains(.messages) ? nil : parent.messages
                self.temperature = omitted.contains(.temperature) ? nil : parent.temperature
                self.stream = omitted.contains(.stream) ? nil : parent.stream
                self.stream_options = omitted.contains(.stream_options) ? nil : parent.stream_options
                self.tools = omitted.contains(.tools) ? nil : parent.tools
            }
            // Remove nils from JSON
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: ParamKey.self)
                if let model = model        { try container.encode(model, forKey: .model) }
                if let messages = messages  { try container.encode(messages, forKey: .messages) }
                if let temperature = temperature { try container.encode(temperature, forKey: .temperature) }
                if let stream = stream      { try container.encode(stream, forKey: .stream) }
                if let stream_options = stream_options { try container.encode(stream_options, forKey: .stream_options) }
                if let tools = tools        { try container.encode(tools, forKey: .tools) }
            }
        }
        let wrapper = OmitWrapper(from: self, omitted: omittedParams)
        // Encode and return
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(wrapper),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        // Log call
        Self.logger.info("Made API call with parameters: \(jsonString, privacy: .public)")
        // Return JSON
        return jsonString
    }
    
    /// Enum representing all possible chat parameter keys
    public enum ParamKey: String, CaseIterable, CodingKey {
        case model
        case messages
        case temperature
        case stream
        case stream_options
        case tools
    }
	
	/// Function to get the name of the model that will be used
	public static func getModelName(
		modelType: ModelType
	) -> String? {
		// Return nil if server is unused
		if !InferenceSettings.useServer {
			return nil
		}
		// Else, get name
		switch modelType {
			case .regular:
				return InferenceSettings.serverModelName
			case .worker:
				let workerModelName: String = InferenceSettings.serverWorkerModelName
				if workerModelName.isEmpty {
					return InferenceSettings.serverModelName
				}
				return workerModelName
            case .completions:
                return InferenceSettings.completionsModelUrl?
                    .deletingLastPathComponent().lastPathComponent
        }
	}
	
	struct SystemPrompt: Codable {
		
		var prompt: String
		var anti_prompt : String = "user:"
		var assistant_name: String = "assistant:"
		
		var wrapper: SystemPromptWrapper {
			.init(system_prompt: self)
		}
		
		public struct SystemPromptWrapper: Codable {
			
			var system_prompt: SystemPrompt
			
			/// Function to convert chat parameters to JSON
			public func toJSON() -> String {
				let encoder = JSONEncoder()
				encoder.outputFormatting = .prettyPrinted
				let jsonData = try? encoder.encode(self)
				return String(data: jsonData!, encoding: .utf8)!
			}
			
		}
	}
	
	struct StreamOptions: Codable {
		var include_usage: Bool = true
	}
	
}
