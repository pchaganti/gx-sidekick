//
//  RemoteModel.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation

public struct RemoteModel: Identifiable, Codable {
    
    /// A `UUID` to conform to `Identifiable`
    public var id: UUID = UUID()
    
    /// A `String` for the model's primary name
    public var primaryName: String
    
    /// The ``Organization`` that trained the model
    public var organization: Organization
    
    /// An array of supported ``Modality``
    public var modalities: [Modality]
    /// A `Bool` representing whethe the model is multimodal
    public var isMultimodal: Bool {
        return modalities.count > 1
    }
    
    /// An array of supported ``Capability``
    public var capabilities: [Capability] = []
    /// A `Bool` representing whethe the model is capable of reasoning
    public var isReasoningModel: Bool {
        return self.capabilities.contains(.reasoning)
    }
    
    /// Organizations that train models
    public enum Organization: String, Codable, CaseIterable {
        case alibaba = "Alibaba"
        case amazon = "Amazon"
        case anthropic = "Anthropic"
        case deepSeek = "DeepSeek"
        case google = "Google"
        case meta = "Meta"
        case microsoft = "Microsoft"
        case mistral = "Mistral"
        case openAi = "OpenAI"
        case xAi = "xAI"
    }
    
    /// Modalities supported by models
    public enum Modality: Codable, CaseIterable {
        case audio
        case image
        case text
    }
    
    /// Capabilities supported by models
    public enum Capability: String, Codable, CaseIterable {
        case reasoning
    }
    
    /// A list of popular models
    public static let popularModels: [RemoteModel] = [
        // Alibaba
        RemoteModel(
            primaryName: "qwen-vl",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "qwen2.5-vl-3b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "qwen2.5-vl-7b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "qwen2.5-vl-32b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "qwen2.5-vl-72b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "qvq-max",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "qvq-plus",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "qvq-72b",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "qwq-32b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "qwq-max",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "qwq-plus",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        
        // Amazon
        RemoteModel(
            primaryName: "nova-lite-v1",
            organization: .amazon,
            modalities: [
                .text,
                .image,
                .audio
            ]
        ),
        
        // Anthropic
        RemoteModel(
            primaryName: "claude-3-haiku",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "claude-3-opus",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "claude-3-sonnet",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "claude-3.5-haiku",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "claude-3.5-sonnet",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "claude-3.7-sonnet",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "claude-3.7-sonnet-thinking",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        
        // Google
        RemoteModel(
            primaryName: "gemini-flash-1.5",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gemini-flash-1.5-8b",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gemini-2.0-flash",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gemini-2.0-pro",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gemini-2.5-pro",
            organization: .google,
            modalities: [
                .text,
                .image,
                .audio
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "gemma-3-4b-it",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gemma-3-12b-it",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gemma-3-27b-it",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "google/gemini-pro-1.5",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // Microsoft
        RemoteModel(
            primaryName: "phi-4-multimodal-instruct",
            organization: .microsoft,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // Meta
        RemoteModel(
            primaryName: "llama-3.2-11b-vision-instruct",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "llama-3.2-90b-vision-instruct",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "llama-4-scout",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "llama-4-maverick",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // OpenAI
        RemoteModel(
            primaryName: "o1",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "o1-pro",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "o3",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "o3-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "o4",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "o4-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        RemoteModel(
            primaryName: "gpt-4-vision",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gpt-4-turbo",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gpt-4o-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gpt-4o",
            organization: .openAi,
            modalities: [
                .text,
                .image,
                .audio
            ]
        ),
        RemoteModel(
            primaryName: "gpt-4.1-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gpt-4.1-nano",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gpt-4.1",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        RemoteModel(
            primaryName: "gpt-4.5",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
    ]
    
}
