//
//  KnownModel.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation

// MARK: - OpenRouter API Response Structures

struct OpenRouterResponse: Codable {
    let data: [OpenRouterModel]
}

struct OpenRouterModel: Codable {
    let id: String
    let name: String
    let description: String?
    let contextLength: Int
    let architecture: OpenRouterArchitecture
    let pricing: OpenRouterPricing
    let supportedParameters: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, architecture, pricing
        case contextLength = "context_length"
        case supportedParameters = "supported_parameters"
    }
}

struct OpenRouterArchitecture: Codable {
    let modality: String
    let inputModalities: [String]?
    let outputModalities: [String]?
    
    enum CodingKeys: String, CodingKey {
        case modality
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
    }
}

struct OpenRouterPricing: Codable {
    let prompt: String
    let completion: String
}

// MARK: - KnownModel

public struct KnownModel: Identifiable, Codable {
    
    init(
        id: UUID = UUID(),
        primaryName: String,
        displayName: String? = nil,
        organization: Organization,
        modalities: [Modality] = [.text],
        capabilities: [Capability] = [],
    ) {
        self.id = id
        self.primaryName = primaryName
        self.displayName = displayName
        self.organization = organization
        self.modalities = modalities
        self.capabilities = capabilities
        self.isReasoningModel = capabilities.contains(.reasoning)
    }
    
    /// Initializes a KnownModel by searching through cached OpenRouter models
    /// Uses the cached `availableModels` for lookup
    init?(
        identifier: String
    ) {
        // Find model containing identifier in cached models
        for model in Self.availableModels {
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
    
    /// Initializes a KnownModel by searching through a provided array of models
    /// - Parameter identifier: The identifier to search for
    /// - Parameter models: The array of models to search in
    init?(
        identifier: String,
        in models: [KnownModel]
    ) {
        // Find model containing identifier
        for model in models {
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
    
    /// Finds a model by identifier from a collection of models
    public static func findModel(byIdentifier identifier: String, in models: [KnownModel]) -> KnownModel? {
        for model in models {
            let idContainsName = identifier.lowercased().contains(model.primaryName.lowercased())
            let nameContainsId = model.primaryName.lowercased().contains(identifier.lowercased())
            if idContainsName || nameContainsId {
                return model
            }
        }
        return nil
    }
    
    /// Asynchronously finds a model by identifier from OpenRouter API
    public static func findModel(byIdentifier identifier: String) async -> KnownModel? {
        do {
            let models = try await fetchModelsFromOpenRouter()
            return findModel(byIdentifier: identifier, in: models)
        } catch {
            print("Failed to fetch models: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// A `UUID` to conform to `Identifiable`
    public var id: UUID = UUID()
    
    /// A `String` for the model's primary name (technical identifier)
    public var primaryName: String
    
    /// A `String` for the model's display name (human-readable name from API)
    public var displayName: String?
    
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
    
    /// A `Bool` representing whethe the model is capable of reasoning
    public var isReasoningModel: Bool
    
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
        
        /// Maps a string identifier to an Organization case
        public static func from(string: String) -> Organization? {
            let normalized = string.lowercased()
            switch normalized {
                case "alibaba", "qwen":
                    return .alibaba
                case "amazon":
                    return .amazon
                case "anthropic":
                    return .anthropic
                case "deepseek":
                    return .deepSeek
                case "google":
                    return .google
                case "meta", "meta-llama":
                    return .meta
                case "microsoft":
                    return .microsoft
                case "minimax":
                    return .minimax
                case "mistral", "mistralai":
                    return .mistral
                case "moonshot", "moonshotai":
                    return .moonshotai
                case "openai":
                    return .openAi
                case "xai", "x-ai":
                    return .xAi
                case "zhipu", "thudm":
                    return .zhipu
                default:
                    return nil
            }
        }
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
    
    // MARK: - Model Cache
    
    /// Cached models from OpenRouter API
    private static var cachedModels: [KnownModel]?
    
    /// File URL for persistent cache storage
    private static var cacheFileURL: URL? {
        let cacheDirUrl: URL = Settings.cacheUrl
        if !FileManager.default.fileExists(atPath: cacheDirUrl.path) {
            try? FileManager.default.createDirectory(at: cacheDirUrl, withIntermediateDirectories: true)
        }
        return Settings.cacheUrl.appendingPathComponent("openrouter_models_cache.json")
    }
    
    /// Synchronously returns cached models if available
    /// Note: Returns empty array if models haven't been fetched yet
    /// Call `initializeModelCache()` at app startup to load from file and refresh from API
    public static var availableModels: [KnownModel] {
        return cachedModels ?? []
    }
    
    /// Loads models from the cached JSON file
    private static func loadModelsFromFile() -> [KnownModel]? {
        guard let fileURL = cacheFileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let models = try JSONDecoder().decode([KnownModel].self, from: data)
            return models
        } catch {
            print("Failed to load models from cache file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Saves models to the cached JSON file
    private static func saveModelsToFile(_ models: [KnownModel]) {
        guard let fileURL = cacheFileURL else {
            print("⚠️ Unable to determine cache file URL")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(models)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save models to cache file: \(error.localizedDescription)")
        }
    }
    
    /// Initializes the model cache by loading from file first, then refreshing from API in background
    /// This provides immediate availability of cached models while fetching fresh data
    public static func initializeModelCache() async {
        // First, try to load from file for immediate availability
        if let fileModels = loadModelsFromFile() {
            cachedModels = fileModels
        }
        
        // Then refresh from API in background
        await refreshModelCache()
    }
    
    /// Refreshes the model cache from OpenRouter API and saves to file
    public static func refreshModelCache() async {
        do {
            let models = try await getAvailableModels()
            cachedModels = models
            
            // Save to file for next launch
            saveModelsToFile(models)
            
        } catch {
            print("Failed to refresh model cache from API: \(error.localizedDescription)")
            
            // If we don't have any cached models and API fails, try file as fallback
            if cachedModels == nil, let fileModels = loadModelsFromFile() {
                cachedModels = fileModels
            } else if cachedModels == nil {
                cachedModels = []
            }
        }
    }
    
    /// Clears the model cache (both in-memory and file)
    public static func clearModelCache() {
        cachedModels = nil
        
        if let fileURL = cacheFileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    // MARK: - OpenRouter API Integration
    
    /*
     Usage Examples:
     
     1. Initialize cache at app startup (REQUIRED - loads from file immediately, then refreshes from API):
     ```swift
     // In your App struct or main view
     Task {
     await KnownModel.initializeModelCache()
     }
     ```
     
     2. Access cached models synchronously (available immediately after initializeModelCache):
     ```swift
     let models = KnownModel.availableModels
     if let claudeModel = models.first(where: { $0.primaryName.contains("claude") }) {
     print("Found: \(claudeModel.primaryName)")
     }
     ```
     
     3. Manually refresh cache from API:
     ```swift
     Task {
     await KnownModel.refreshModelCache()
     }
     ```
     
     4. Clear cache (useful for debugging or settings):
     ```swift
     KnownModel.clearModelCache()
     ```
     
     5. Fetch all models from OpenRouter API (without caching):
     ```swift
     Task {
     do {
     let models = try await KnownModel.fetchModelsFromOpenRouter()
     print("Fetched \(models.count) models from OpenRouter")
     } catch {
     print("Error fetching models: \(error)")
     }
     }
     ```
     
     6. Get available models (filtered by known organizations):
     ```swift
     Task {
     do {
     let models = try await KnownModel.getAvailableModels()
     print("Available models: \(models.count)")
     } catch {
     print("Error: \(error)")
     }
     }
     ```
     
     7. Find a specific model by identifier:
     ```swift
     Task {
     if let model = await KnownModel.findModel(byIdentifier: "claude-sonnet-4.5") {
     print("Found model: \(model.primaryName)")
     }
     }
     ```
     */
    
    /// Fetches models from the OpenRouter API
    /// - Returns: An array of KnownModel instances parsed from the API response
    /// - Throws: Network or decoding errors
    public static func fetchModelsFromOpenRouter() async throws -> [KnownModel] {
        let url = URL(string: "https://openrouter.ai/api/v1/models")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        return response.data.compactMap { openRouterModel in
            KnownModel(from: openRouterModel)
        }
    }
    
    /// Returns available models from the OpenRouter API
    /// - Parameter includeOnlyKnownOrganizations: If true, filters out models from unknown organizations
    /// - Returns: An array of KnownModel instances, or throws an error if the API call fails
    public static func getAvailableModels(includeOnlyKnownOrganizations: Bool = true) async throws -> [KnownModel] {
        var models = try await fetchModelsFromOpenRouter()
        if includeOnlyKnownOrganizations {
            // Filter to only include models from known organizations
            let knownOrgNames = Set(Organization.allCases.map { $0.rawValue.lowercased() })
            models = models.filter { model in
                knownOrgNames.contains(model.organization.rawValue.lowercased())
            }
        }
        return models
    }
    
    /// Returns available models from the OpenRouter API with error handling
    /// - Parameter includeOnlyKnownOrganizations: If true, filters out models from unknown organizations
    /// - Returns: An array of KnownModel instances, or an empty array if the API call fails
    public static func getAvailableModelsSafe(includeOnlyKnownOrganizations: Bool = true) async -> [KnownModel] {
        do {
            return try await getAvailableModels(includeOnlyKnownOrganizations: includeOnlyKnownOrganizations)
        } catch {
            print("Failed to fetch models from OpenRouter API: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Initializes a KnownModel from an OpenRouter API model
    private init?(from openRouterModel: OpenRouterModel) {
        // Extract organization from the model ID (format: "organization/model-name")
        let components = openRouterModel.id.split(separator: "/")
        guard components.count >= 2 else { return nil }
        
        let orgString = String(components[0]).lowercased()
        guard let org = Organization.from(string: orgString) else { return nil }
        
        // Extract model name (everything after the first "/")
        let modelName = components.dropFirst().joined(separator: "/")
        
        // Parse modalities
        var modalities: [Modality] = []
        if let inputModalities = openRouterModel.architecture.inputModalities {
            if inputModalities.contains("text") {
                modalities.append(.text)
            }
            if inputModalities.contains("image") {
                modalities.append(.image)
            }
            if inputModalities.contains("audio") {
                modalities.append(.audio)
            }
        } else {
            // Fallback to parsing the modality string
            if openRouterModel.architecture.modality.contains("text") {
                modalities.append(.text)
            }
            if openRouterModel.architecture.modality.contains("image") {
                modalities.append(.image)
            }
        }
        
        // Determine if it's a reasoning model
        var capabilities: [Capability] = []
        let lowerName = modelName.lowercased()
        let lowerDescription = openRouterModel.name.lowercased()
        
        // Check if model supports reasoning parameters in the API
        let hasReasoningParams = openRouterModel.supportedParameters?.contains { param in
            param.lowercased().contains("reasoning") || param.lowercased() == "include_reasoning"
        } ?? false
        
        // Check model name and description for reasoning indicators
        let hasReasoningInName = lowerName.contains("thinking") || lowerName.contains("reasoning") ||
        lowerName.contains("o1") || lowerName.contains("o3") || lowerName.contains("o4") ||
        lowerName.contains("r1") || lowerName.contains("qwq") || lowerName.contains("qvq") ||
        lowerName.contains("deepseek-reasoner") || lowerName.contains("minimax-m") ||
        lowerName.contains("glm-z") || lowerName.contains("kimi-k2-thinking") ||
        lowerName.contains("phi-4-reasoning") || lowerDescription.contains("thinking")
        
        if hasReasoningParams || hasReasoningInName {
            capabilities.append(.reasoning)
        }
        
        self.init(
            primaryName: modelName,
            displayName: openRouterModel.name,
            organization: org,
            modalities: modalities,
            capabilities: capabilities
        )
    }
    
}
