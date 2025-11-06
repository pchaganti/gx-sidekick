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
        self.isReasoningModel = capabilities.contains(.reasoning)
    }
    
    init?(
        identifier: String
    ) {
        // Find model containing identifier
        for model in Self.popularModels {
            let idContainsName: Bool = identifier.lowercased().contains(model.primaryName.lowercased())
            let nameContainsId: Bool = model.primaryName.lowercased().contains(identifier.lowercased())
            if idContainsName || nameContainsId {
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
    public var isVision: Bool {
        return modalities.count > 1
    }
    
    /// An array of supported ``Capability``
    public var capabilities: [Capability] = []
    
    /// The model's hybrid reasoning style
    public var hybridReasoningStyle: HybridReasoningStyle? = nil
    /// A `Bool` representing whethe the model is capable of reasoning
    public var isReasoningModel: Bool
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
        case minimax = "Minimax"
        case mistral = "Mistral"
        case moonshotai = "Moonshot AI"
        case openAi = "OpenAI"
        case xAi = "xAI"
        case zhipu = "Zhipu"
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
        case glm4pt5
        
        /// Tag to trigger thinking
        public var triggerThinkingTag: String {
            switch self {
                case .qwen3:
                    return "/think"
                case .glm4pt5:
                    return ""
            }
        }
        
        /// Tag to skip thinking
        public var skipThinkingTag: String {
            switch self {
                case .qwen3:
                    return "/no_think"
                case .glm4pt5:
                    return ""
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
        
        // Moonshot AI
        KnownModel(
            primaryName: "kimi-k2",
            organization: .moonshotai,
            modalities: [
                .text
            ]
        ),
        KnownModel(
            primaryName: "kimi-k2-thinking",
            organization: .moonshotai,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
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
            primaryName: "qwen3-0.6b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-1.7b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-4b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-4b-instruct-2507",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-4b-thinking-2507",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwen3-8b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-14b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-30b-a3b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-30b-a3b-instruct-2507",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-30b-a3b-thinking-2507",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwen3-32b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-235b-a22b",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .qwen3
        ),
        KnownModel(
            primaryName: "qwen3-235b-a22b-instruct-2507",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-235b-a22b-thinking-2507",
            organization: .alibaba,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        
        // Qwen3-VL
        
        KnownModel(
            primaryName: "qwen3-vl-2b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-vl-2b-thinking",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwen3-vl-4b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-vl-4b-thinking",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwen3-vl-8b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-vl-8b-thinking",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwen3-vl-32b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-vl-32b-thinking",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwen3-vl-30b-a3b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-vl-30b-a3b-thinking",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "qwen3-vl-235b-a22b-instruct",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: []
        ),
        KnownModel(
            primaryName: "qwen3-vl-235b-a22b-thinking",
            organization: .alibaba,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
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
        
        // Zhipu
        
        KnownModel(
            primaryName: "glm-4v",
            organization: .zhipu,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "glm-z1",
            organization: .zhipu,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "glm-4.5",
            organization: .zhipu,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .glm4pt5
        ),
        KnownModel(
            primaryName: "glm-4.5-air",
            organization: .zhipu,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .glm4pt5
        ),
        KnownModel(
            primaryName: "glm-4.5v",
            organization: .zhipu,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .glm4pt5
        ),
        KnownModel(
            primaryName: "glm-4.6",
            organization: .zhipu,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .glm4pt5
        ),
        KnownModel(
            primaryName: "glm-4.6-air",
            organization: .zhipu,
            modalities: [
                .text
            ],
            capabilities: [.reasoning],
            hybridReasoningStyle: .glm4pt5
        ),
        
        // Minimax
        
        KnownModel(
            primaryName: "minimax-m1",
            organization: .minimax,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "minimax-m2",
            organization: .minimax,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        
        // DeepSeek
        
        KnownModel(
            primaryName: "deepseek-r1",
            organization: .deepSeek,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "deepseek-v3",
            organization: .deepSeek,
            modalities: [
                .text
            ]
        ),
        KnownModel(
            primaryName: "deepseek-v3.1",
            organization: .deepSeek,
            modalities: [
                .text
            ]
        ),
        KnownModel(
            primaryName: "deepseek-v3.1-terminus",
            organization: .deepSeek,
            modalities: [
                .text
            ]
        ),
        KnownModel(
            primaryName: "deepseek-v3.2",
            organization: .deepSeek,
            modalities: [
                .text
            ]
        ),
        KnownModel(
            primaryName: "deepseek-reasoner",
            organization: .deepSeek,
            modalities: [
                .text
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "deepseek-chat",
            organization: .deepSeek,
            modalities: [
                .text
            ]
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
            primaryName: "claude-3.7-sonnet:thinking",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "claude-sonnet-4",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-sonnet-4:thinking",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "claude-opus-4",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "claude-opus-4:thinking",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "claude-opus-4.1",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "claude-sonnet-4.5",
            organization: .anthropic,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "claude-haiku-4.5",
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
            primaryName: "gemini-2.5-flash-lite",
            organization: .google,
            modalities: [
                .text,
                .image,
                .audio
            ],
            capabilities: [.reasoning]
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
            primaryName: "gemini-3.0-flash-lite",
            organization: .google,
            modalities: [
                .text,
                .image,
                .audio
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "gemini-3.0-flash",
            organization: .google,
            modalities: [
                .text,
                .image,
                .audio
            ],
            capabilities: [.reasoning]
        ),
        KnownModel(
            primaryName: "gemini-3.0-pro",
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
        KnownModel(
            primaryName: "phi-4-reasoning",
            organization: .microsoft,
            modalities: [
                .text,
                .image
            ],
            capabilities: [.reasoning]
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
            primaryName: "gpt-5-nano",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-5-mini",
            organization: .openAi,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "gpt-5",
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
        
        // Mistral
        
        KnownModel(
            primaryName: "mistral-small",
            organization: .mistral,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "magistral-small",
            organization: .mistral,
            modalities: [
                .text,
                .image
            ]
        ),
        KnownModel(
            primaryName: "magistral-medium",
            organization: .mistral,
            modalities: [
                .text,
                .image
            ]
        ),
        
    ]
    
}
