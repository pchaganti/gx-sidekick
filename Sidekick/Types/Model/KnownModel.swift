//
//  KnownModel.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation

public struct KnownModel: Identifiable, Codable {
    
    init(
        id: UUID = UUID(),
        primaryName: String,
        organization: Organization,
        modalities: [Modality] = [.text],
        capabilities: [Capability] = [],
        hybridReasoningStyle: HybridReasoningStyle? = nil
    ) {
        self.id = id
        self.primaryName = primaryName
        self.organization = organization
        self.modalities = modalities
        self.capabilities = capabilities
        self.hybridReasoningStyle = hybridReasoningStyle
    }
    
    init?(
        identifier: String
    ) {
        // Find model containing identifier
        for model in Self.popularModels {
            if model.primaryName.lowercased().contains(identifier.lowercased()) {
                self = model
                return
            }
        }
        // If fell through, return nil
        return nil
    }
    
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
    
    /// The model's hybrid reasoning style
    public var hybridReasoningStyle: HybridReasoningStyle? = nil
    /// A `Bool` representing whethe the model is capable of reasoning
    public var isReasoningModel: Bool {
        return self.capabilities.contains(.reasoning)
    }
    /// A `Bool` representing whethe the model is capable of toggling reasoning
    public var isHybridReasoningModel: Bool {
        return self.hybridReasoningStyle != nil && self.capabilities.contains(.reasoning)
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
    public enum Capability: Codable, CaseIterable {
        case reasoning
    }
    
    /// Hybrid reasoning style
    public enum HybridReasoningStyle: String, Codable, CaseIterable {
        
        case qwen3
        
        /// Tag to trigger thinking
        public var triggerThinkingTag: String {
            switch self {
                case .qwen3:
                    return "/think"
            }
        }
        
        /// Tag to skip thinking
        public var skipThinkingTag: String {
            switch self {
                case .qwen3:
                    return "/no_think"
            }
        }
        
        /// Function to get the tag
        public func getTag(
            useReasoning: Bool
        ) -> String {
            return useReasoning ? self.triggerThinkingTag : self.skipThinkingTag
        }
        
    }
    
    /// A list of popular models
    public static let popularModels: [KnownModel] = [
        
        // Alibaba
        KnownModel(
            primaryName: "qwen-vl",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // Qwen2.5-VL
        
        KnownModel(
            primaryName: "qwen2.5-vl-3b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "qwen2.5-vl-7b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "qwen2.5-vl-32b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "qwen2.5-vl-72b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // Qwen3
        
        KnownModel(
            primaryName: "qwen3-0.6b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-1.7b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-4b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-8b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-14b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-15b-a2b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-30b-a3b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-235b-a22b-instruct",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        
        // QvQ
        
        KnownModel(
            primaryName: "qvq-max",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qvq-plus",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qvq-72b",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        
        // QwQ
        
        KnownModel(
            primaryName: "qwq-32b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwq-max",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwq-plus",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        
        // Amazon
        KnownModel(
            primaryName: "nova-lite-v1",
            organization: .amazon,
            modalities: [
                .text,
                .image,
                .audio
            ]
        ),
        
        // Anthropic
        KnownModel(
            primaryName: "claude-3-haiku",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-3-opus",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-3-sonnet",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-3.5-haiku",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-3.5-sonnet",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-3.7-sonnet",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-3.7-sonnet-thinking",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        
        // Google
        KnownModel(
            primaryName: "gemini-flash-1.5",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gemini-flash-1.5-8b",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gemini-2.0-flash",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gemini-2.0-pro",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gemini-2.5-flash",
            organization: .google,
            modalities: [
                .text,
                .image,
                .audio
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "gemini-2.5-pro",
            organization: .google,
            modalities: [
                .text,
                .image,
                .audio
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "gemma-3-4b-it",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gemma-3-12b-it",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gemma-3-27b-it",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "google/gemini-pro-1.5",
            organization: .google,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // Microsoft
        KnownModel(
            primaryName: "phi-4-multimodal-instruct",
            organization: .microsoft,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // Meta
        KnownModel(
            primaryName: "llama-3.2-11b-vision-instruct",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "llama-3.2-90b-vision-instruct",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "llama-4-scout",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "llama-4-maverick",
            organization: .meta,
            modalities: [
                .text,
                .image
            ]
        ),
        
        // OpenAI
        KnownModel(
            primaryName: "o1",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "o1-pro",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "o3",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "o3-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "o4",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "o4-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "gpt-4-vision",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-4-turbo",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-4o-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-4o",
            organization: .openAi,
            modalities: [
                .text,
                .image,
                .audio
            ]
        ),
        KnownModel(
            primaryName: "gpt-4.1-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-4.1-nano",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-4.1",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-4.5",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
    ]
    
}
