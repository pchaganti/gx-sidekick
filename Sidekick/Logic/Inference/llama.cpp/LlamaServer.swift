//
//  LlamaServer.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import EventSource
import Foundation
import FSKit_macOS
import OSLog
import SimilaritySearchKit

/// The inference server where LLM inference happens
public actor LlamaServer {
	
	/// A `Logger` object for the `LlamaServer` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: LlamaServer.self)
	)
	
    /// Initializes the inference server object
    /// - Parameters:
    ///   - modelUrl: The url linking to the model
    ///   - systemPrompt: The system prompt passed to the model, which controls its behaviour
    ///   - modelType: The type of the model
    ///   - port: The port on which a local server is made available
	init(
        modelType: ModelType,
		systemPrompt: String = InferenceSettings.systemPrompt
    ) {
        self.modelType = modelType
        self.systemPrompt = systemPrompt
        self.port = {
            switch modelType {
                case .regular:
                    return "4579"
                case .worker:
                    return "9830"
                case .completions:
                    return "1623"
            }
        }()
    }
	
	/// The `URL` of the local model
	private var modelUrl: URL? {
        switch self.modelType {
            case .regular:
                return Settings.modelUrl
            case .worker:
                return InferenceSettings.workerModelUrl
            case .completions:
                return InferenceSettings.completionsModelUrl
        }
	}
	
	/// The IP address of the inference server's host
	private var host: String = "127.0.0.1"
	/// The port where the inference server is accessible
	private var port: String
	/// The scheme through which the inference server is accessible
	private var scheme: String = "http"
	
	/// A `Bool` indicating if the server is being started
	private var isStartingServer: Bool = false
	
	/// An `EventSource` instance opening a persistent connection to an HTTP server, which sends stream events
	private var eventSource: EventSource?
	///	An EventSource task handling connecting to the URLRequest and creating an event stream
	private var dataTask: EventSource.DataTask?
	
	/// The name of the LLM, of type `String`
	var modelName: String {
		return self.modelUrl?.deletingPathExtension().lastPathComponent ?? "Unknown Model"
	}
    /// The type of the LLM, of type ``ModelType``
    var modelType: ModelType
    /// Function to check whether the model is vision capable
    func modelHasVision(
        usingRemoteModel: Bool
    ) -> Bool {
        return Self.modelHasVision(
            type: self.modelType,
            usingRemoteModel: usingRemoteModel
        )
    }
    /// Function to check whether the model is vision capable
    static func modelHasVision(
        type: ModelType,
        usingRemoteModel: Bool
    ) -> Bool {
        // Return false if...
        // Using local model since `llama-server` does not yet support VLMs
        // Using non-regular model
        if !usingRemoteModel || type != .regular {
            return false
        }
        // Else, get toggle value
        return InferenceSettings.serverModelHasVision
    }
	
	/// The system prompt given to the chatbot
	var systemPrompt: String
	
	/// The context length used in chat completion
	var contextLength: Int = InferenceSettings.contextLength
	
	/// Property for `llama-server-watchdog` process
	private var monitor: Process = Process()
	/// Property for `llama-server` process
	private var process: Process = Process()
	
	/// Function to set system prompt
	/// - Parameter systemPrompt: The system prompt, of type `String`
	public func setSystemPrompt(_ systemPrompt: String) {
		self.systemPrompt = systemPrompt
	}
	
	/// Function to get the `URL` at which the inference server is accessible
	/// - Parameter path: The endpoint accessed via this `URL`
	/// - Returns: The `URL` at which the inference server is accessible
	private func url(
		_ path: String,
        openAiCompatiblePath: Bool,
        canReachRemoteServer: Bool,
		mustUseLocalServer: Bool = false
	) async -> (
		url: URL,
		usingRemoteServer: Bool
	) {
		// Check endpoint
		let endpoint: String = InferenceSettings.endpoint.replacingSuffix(
			"/chat/completions",
			with: ""
		)
		let urlString: String
        let notUsingServer: Bool = !canReachRemoteServer || !InferenceSettings.useServer
		if notUsingServer || mustUseLocalServer {
            let addV1: String = openAiCompatiblePath ? "/v1" : ""
            urlString = "\(self.scheme)://\(self.host):\(self.port)\(addV1)\(path)"
		} else {
			urlString = "\(endpoint)\(path)"
		}
		return (URL(string: urlString)!, !notUsingServer)
	}
	
	/// Function to get a list of available models on the server
	public static func getAvailableModels() async -> [String] {
		// Set up request
		guard let modelsEndpoint: URL = URL(
			string: InferenceSettings.endpoint + "/models"
		) else {
			return []
		}
		var request: URLRequest = URLRequest(
			url: modelsEndpoint
		)
		request.httpMethod = "GET"
		request.setValue(
			"Bearer \(InferenceSettings.inferenceApiKey)",
			forHTTPHeaderField: "Authorization"
		)
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		let urlSession: URLSession = URLSession.shared
		urlSession.configuration.waitsForConnectivity = false
		urlSession.configuration.timeoutIntervalForRequest = 2
		urlSession.configuration.timeoutIntervalForResource = 2
		// Get JSON response
		guard let (data, _): (Data, URLResponse) = try? await URLSession.shared.data(
			for: request
		) else {
			Self.logger.error("Failed to fetch models from endpoint '\(modelsEndpoint.absoluteString, privacy: .public)'")
			return []
		}
		// Decode and return
		let decoder: JSONDecoder = JSONDecoder()
		let response: AvailableModelsResponse? = try? decoder.decode(
			AvailableModelsResponse.self,
			from: data
		)
		let models: [String] = (response?.data ?? []).map({ $0.id })
		Self.logger.info("Fetched \(models.count, privacy: .public) models from endpoint '\(modelsEndpoint.absoluteString, privacy: .public)'")
		return models.sorted()
	}
	
	/// Function to start a monitor process that will terminate the server when our app dies
	/// - Parameter serverPID: The process identifier of `llama-server`, of type `pid_t`
	private func startAppMonitor(
		serverPID: pid_t
	) throws {
		// Start `llama-server-watchdog`
		monitor = Process()
		monitor.executableURL = Bundle.main.url(forAuxiliaryExecutable: "llama-server-watchdog")
		monitor.arguments = [
			String(serverPID)
		]
		// Send main app's heartbeat to show that the main app is still running
		let heartbeat = Pipe()
		let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
		timer.schedule(deadline: .now(), repeating: 15.0)
		timer.setEventHandler { [weak heartbeat] in
			guard let heartbeat = heartbeat else { return }
			let data = ".".data(using: .utf8) ?? Data()
			heartbeat.fileHandleForWriting.write(data)
		}
		timer.resume()
		monitor.standardInput = heartbeat
		// Start monitor
		try monitor.run()
		Self.logger.notice(
			"Started monitor for server with PID \(serverPID)"
		)
	}
	
	/// Function to start the `llama-server` process
	public func startServer(
        canReachRemoteServer: Bool
    ) async throws {
		// If a model is missing, throw error
		let hasModel: Bool = self.modelUrl?.fileExists ?? false
        let usesSpeculativeModel: Bool = InferenceSettings.useSpeculativeDecoding && self.modelType == .regular
		let hasSpeculativeModel: Bool = InferenceSettings.speculativeDecodingModelUrl?.fileExists ?? false
		if !hasModel || (usesSpeculativeModel && !hasSpeculativeModel) {
			Self.logger.error("Main model or draft model is missing")
			throw LlamaServerError.modelError
		}
		// If server is running, or is starting server, or no model, exit
        guard !process.isRunning,
                !self.isStartingServer,
                let modelPath = self.modelUrl?.posixPath else {
            return
        }
		// Signal beginning of server initialization
		self.isStartingServer = true
		// Stop server if running
		await stopServer()
		// Initialize `llama-server` process
		process = Process()
		let startTime: Date = Date.now
		process.executableURL = Bundle.main.resourceURL?.appendingPathComponent("llama-server")
		
		let gpuLayers: Int = 99
		let processors: Int = ProcessInfo.processInfo.activeProcessorCount
		let threadsToUseIfGPU: Int = max(1, Int(ceil(Double(processors) / 3.0 * 2.0)))
		let threadsToUseIfCPU: Int = processors
		let threadsToUse: Int = InferenceSettings.useGPUAcceleration ? threadsToUseIfGPU : threadsToUseIfCPU
		let gpuLayersToUse: String = InferenceSettings.useGPUAcceleration ? "\(gpuLayers)" : "0"
		
        // Formulate arguments
        var arguments: [String: String?] = [
            "--model": modelPath,
            "--threads": "\(threadsToUse)",
            "--threads-batch": "\(threadsToUse)",
            "--ctx-size": "\(contextLength)",
            "--port": self.port,
            "--gpu-layers": gpuLayersToUse
		]
		// If speculative decoding is used and is main model
        if self.modelType == .regular,
			let speculationModelUrl = InferenceSettings.speculativeDecodingModelUrl {
			if InferenceSettings.useSpeculativeDecoding {
				// Formulate arguments
				let draft: Int =  16
				let draftMin: Int = 7
				let draftPMin: Double = 0.75
                let speculativeDecodingArguments: [String: String?] = [
                    "--model-draft": speculationModelUrl.posixPath,
                    "--gpu-layers-draft": "\(gpuLayersToUse)",
                    "--draft-p-min": "\(draftPMin)",
                    "--draft": "\(draft)",
                    "--draft-min": "\(draftMin)"
				]
				// Append
                speculativeDecodingArguments.forEach { element in
                    arguments[element.key] = element.value
                }
			}
		}
        // Inject custom arguments for main model
        if self.modelType == .regular {
            // Remove duplicate arguments
            let activeArguments: [ServerArgument] = ServerArgumentsManager.shared.activeArguments
            let activeFlags = activeArguments.map(keyPath: \.flag)
            arguments = arguments.filter { !activeFlags.contains($0.key) }
            // Convert dictionary to [String] format with each key and value as separate elements
            var formattedArguments: [String] = []
            arguments.forEach { key, value in
                formattedArguments.append(key)
                if let value = value, !value.isEmpty {
                    formattedArguments.append(value)
                }
            }
            // Add custom arguments
            let allArguments: [String] = ServerArgumentsManager.shared.allArguments
            formattedArguments += allArguments
            // Assign arguments
            process.arguments = formattedArguments
        } else {
            // Else, just convert and assign
            var formattedArguments: [String] = []
            arguments.forEach { key, value in
                formattedArguments.append(key)
                if let value = value, !value.isEmpty  {
                    formattedArguments.append(value)
                }
            }
            process.arguments = formattedArguments
        }
		
		Self.logger.notice("Starting llama.cpp server \(self.process.arguments!.joined(separator: " "), privacy: .public)")
		
		process.standardInput = FileHandle.nullDevice
		
		// To debug with server's output, comment these 2 lines to inherit stdout.
		process.standardOutput = FileHandle.nullDevice
		process.standardError = FileHandle.nullDevice
		
		try process.run()
		
		try await self.waitForServer(
            canReachRemoteServer: canReachRemoteServer
        )
		
		try startAppMonitor(serverPID: process.processIdentifier)
		
		let endTime: Date = Date.now
		let elapsedTime: Double = endTime.timeIntervalSince(startTime)
		
#if DEBUG
		print("Started server process in \(elapsedTime) secs")
#endif
		self.isStartingServer = false
	}
	
	/// Function to stop the `llama-server` process
	public func stopServer() async {
		// Terminate processes
		if self.process.isRunning {
			self.process.terminate()
		}
		if self.monitor.isRunning {
			self.monitor.terminate()
		}
		self.process = Process()
		self.monitor = Process()
	}
	
	/// Function showing if connection was interrupted
	@EventSourceActor
	public func interrupt() async {
		if let dataTask = await self.dataTask, dataTask.readyState != .closed {
			dataTask.cancel()
		}
	}
	
	/// Function to get a chat completion from the LLM
	/// - Parameters:
	///   - modelType: The type of model used for completion
	///   - mode: The chat completion mode. This controls whether advanced features like resource lookup is used
	///   - messages: A list of prior messages
	///   - similarityIndex: A similarity index for resource lookup
	///   - progressHandler: A handler called after a new token is generated
	/// - Returns: The response returned from the inference server
	public func getChatCompletion(
		mode: Model.Mode,
        canReachRemoteServer: Bool,
		messages: [Message.MessageSubset],
        useWebSearch: Bool = false,
        useFunctions: Bool = false,
        functions: [AnyFunctionBox]? = nil,
        updateStatusHandler: (@Sendable (Model.Status) async -> Void)? = nil,
        progressHandler: (@Sendable (String) -> Void)? = nil
	) async throws -> CompleteResponse {
		// Get endpoint url & whether server is used
        let rawUrl = await self.url(
            "/chat/completions",
            openAiCompatiblePath: true,
            canReachRemoteServer: canReachRemoteServer
        )
		// Start server if remote server is not used & local server is inactive
		if !rawUrl.usingRemoteServer {
			Self.logger.info("Using local model for inference...")
            try await self.startServer(
                canReachRemoteServer: canReachRemoteServer
            )
		} else {
			Self.logger.info("Using remote model for inference...")
		}
        // Get start time
        let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
        // Formulate parameters
        async let params = {
			switch mode {
				case .chat:
					return await ChatParameters(
                        modelType: self.modelType,
                        systemPrompt: self.systemPrompt,
                        messages: messages,
                        useWebSearch: useWebSearch,
                        useFunctions: useFunctions,
                        functions: functions
					)
				case .default:
					return await ChatParameters(
                        modelType: self.modelType,
                        systemPrompt: self.systemPrompt,
                        messages: messages
					)
			}
		}()
		// Formulate request
		var request = URLRequest(
			url: rawUrl.url
		)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
		request.setValue("keep-alive", forHTTPHeaderField: "Connection")
		if rawUrl.usingRemoteServer {
			request.setValue(
				"Bearer \(InferenceSettings.inferenceApiKey)",
				forHTTPHeaderField: "Authorization"
			)
			request.setValue("nil", forHTTPHeaderField: "ngrok-skip-browser-warning")
		}
        // Formulate request JSON
        let omittedParams: [ChatParameters.ParamKey] = {
            switch mode {
                case .chat:
                    if !useFunctions {
                        return [.tools]
                    } else {
                        return []
                    }
                case .`default`:
                    return [.tools]
            }
        }()
		let requestJson: String = await params.toJSON(
            usingRemoteModel: rawUrl.usingRemoteServer,
            modelType: self.modelType,
            omittedParams: omittedParams
        )
		request.httpBody = requestJson.data(using: .utf8)
		// Use EventSource to receive server sent events
		self.eventSource = EventSource(
			timeoutInterval: 6000 // Timeout after 100 minutes, enough for even reasoning models
		)
		self.dataTask = await eventSource!.dataTask(
			for: request
		)
        // Init variables for content
		var pendingMessage: String = ""
		var responseDiff: Double = 0.0
        var wasReasoningToken: Bool = false
        // Init variables for tool use
        var functionName: String? = nil
        var functionArguments: String? = nil
        var blockFunctionCalls: [(any DecodableFunctionCall)] = []
        // Init variables for usage
        var tokenCount: Int = 0
        var usage: Usage? = nil
        // Init variables for control
        var stopResponse: StopResponse? = nil
		// Start streaming completion events
		listenLoop: for await event in await dataTask!.events() {
			switch event {
				case .open:
					continue listenLoop
				case .error(let error):
                    // Log error
					Self.logger.error("Inference server error: \(error, privacy: .public)")
                    // Throw error
                    throw LlamaServerError.errorResponse(error.localizedDescription)
				case .event(let message):
					// Parse json in message.data string
					// Then, print the data.content value and append it to response
					if let data = message.data?.data(using: .utf8) {
						let decoder = JSONDecoder()
						do {
                            // Log response object
                            if let responseStr = String(data: data, encoding: .utf8) {
                                Self.logger.info("Received response object: \(responseStr, privacy: .public)")
                            }
							// Decode response object
							let responseObj: StreamResponse = try decoder.decode(
								StreamResponse.self,
								from: data
							)
							// Run completion handler for update
							let fragment: String = responseObj.choices.map { choice in
								// Init variable
                                var choiceContent: String = choice.delta.content ?? ""
                                if let content: String = choice.delta.content,
                                   !content.isEmpty, wasReasoningToken {
                                    // Handle answer token
									// If previous token was reasoning token, add end of reasoning token
                                    let hasEndReasoningToken: Bool = String.specialReasoningTokens.contains (where: { tokens in
                                        guard let endReasoningToken: String = tokens.last else {
                                            return false
                                        }
                                        return pendingMessage
                                            .trimmingWhitespaceAndNewlines()
                                            .contains(
                                                endReasoningToken
                                            )
                                    })
									choiceContent = (!hasEndReasoningToken ? "\n</think>\n" : "") + content
									wasReasoningToken = false
								} else if let reasoningContent: String = choice.delta.reasoningContent {
                                    // Handle reasoning token
									// If previous token was not reasoning token, add reasoning special token
									choiceContent = (
										wasReasoningToken ? "" : "<think>\n"
									) + reasoningContent
									wasReasoningToken = true
                                }
								// Return result
								return choiceContent
							}.joined()
							pendingMessage.append(fragment)
							progressHandler?(fragment)
                            // Handle tool call (first call only)
                            if let firstChoice = responseObj.choices.first?.delta,
                               let toolCall = firstChoice.tool_calls?.first {
                                // Show progress
                                if let updateStatusHandler {
                                    await updateStatusHandler(.usingFunctions)
                                }
                                // Set function name
                                if let name = toolCall.function.name {
                                    functionName = name
                                }
                                // Add to arguments if needed
                                if let argument = toolCall.function.arguments {
                                    functionArguments = (functionArguments ?? "") + argument
                                }
                                // Extract tool call
                                if let name = functionName,
                                   let args = functionArguments,
                                   let function = StreamMessage.OpenAIToolCall.Function.getFunctionCall(
                                    name: name,
                                    arguments: args
                                   ){
                                    // Append and reset
                                    blockFunctionCalls.append(function)
                                    functionName = nil
                                    functionArguments = nil
                                }
                            }
							// Document usage
							tokenCount += 1
							usage = responseObj.usage
							if responseDiff == 0 {
								responseDiff = CFAbsoluteTimeGetCurrent() - start
							}
                            if responseObj.choices.first?.finish_reason != nil {
								do {
									stopResponse = try decoder.decode(StopResponse.self, from: data)
									break listenLoop
								} catch {
									print("Error decoding stopResponse, listenLoop will continue", error as Any, data)
								}
							}
						} catch {
							Self.logger.error("Error decoding response object \(error, privacy: .public)")
							Self.logger.error("responseObj: \(String(decoding: data, as: UTF8.self), privacy: .public)")
						}
					}
				case .closed:
					Self.logger.notice("EventSource closed")
					break listenLoop
			}
		}
		// Adding a trailing quote or space is a common mistake with the smaller model output
		let cleanText: String = pendingMessage.removeUnmatchedTrailingQuote()
		// Indicate response finished
		if responseDiff > 0 {
			// Call onFinish
			onFinish(text: cleanText)
		}
		// Return info
		let tokens: Int = stopResponse?.usage?.completion_tokens ?? (
			usage?.completion_tokens ?? tokenCount
		)
		let generationTime: CFTimeInterval = CFAbsoluteTimeGetCurrent() - start - responseDiff
		let modelName: String = rawUrl.usingRemoteServer ? InferenceSettings.serverModelName : self.modelName
		return CompleteResponse(
			text: cleanText,
			responseStartSeconds: responseDiff,
			predictedPerSecond: Double(tokens) / generationTime,
			modelName: modelName,
			usage: stopResponse?.usage,
            usedServer: rawUrl.usingRemoteServer,
            blockFunctionCalls: blockFunctionCalls
		)
	}
	
	/// Function to get a completion from the LLM
	/// - Parameter text: The text to complete
	/// - Parameter tokenNumber: The number of tokens to predict
	/// - Returns: A sequence of tokens, each with a probability
	public func getCompletion(
		text: String,
		maxTokenNumber: Int
	) async -> [Token]? {
		// Formulate request
		var request = URLRequest(
			url: URL(
				string: "\(self.scheme)://\(self.host):\(self.port)/v1/completions"
			)!
		)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		// Formulate JSON
		let params: CompletionParams = .init(
			prompt: text,
			max_tokens: maxTokenNumber
		)
		let encoder: JSONEncoder = .init()
		guard let data: Data = try? encoder.encode(params) else {
			return nil
		}
		let requestJson: String = String(
			data: data,
			encoding: .utf8
		)!
		request.httpBody = requestJson.data(using: .utf8)
		// Send request
		let urlSession: URLSession = URLSession.shared
		urlSession.configuration.waitsForConnectivity = false
		urlSession.configuration.timeoutIntervalForRequest = 10
		urlSession.configuration.timeoutIntervalForResource = 10
		// Get JSON response
		guard let (data, _): (Data, URLResponse) = try? await URLSession.shared.data(
			for: request
		) else {
			Self.logger.error("Failed to generate completion.")
			return nil
		}
		// Decode response
		let decoder: JSONDecoder = .init()
		guard let response: CompletionResponse = try? decoder.decode(
			CompletionResponse.self,
			from: data
		) else {
			Self.logger.error("Failed to decode completion response.")
			return nil
		}
		// Extract and return
		return response.choices.first?.logprobs.content
	}
	
	/// Function executed when output finishes
	/// - Parameter text: The output generated by the LLM
	public func onFinish(text: String) {}
	
	/// Function to get number of tokens in a piece of text
	/// - Parameter text: The text for which the number of tokens is calculated
	/// - Returns: The number of tokens in the text
	public func tokenCount(
		in text: String,
        canReachRemoteServer: Bool
	) async throws -> Int {
		// Start server if not active
		if !self.process.isRunning && !self.isStartingServer {
            try await self.startServer(
                canReachRemoteServer: canReachRemoteServer
            )
		}
		// Get url of endpoint
		let rawUrl: URL = URL(string: "\(self.scheme)://\(self.host):\(self.port)/tokenize")!
		// Formulate request
		var request = URLRequest(
			url: rawUrl
		)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("keep-alive", forHTTPHeaderField: "Connection")
		let requestParams: TokenizeParams = .init(content: text)
        let requestJson: String = requestParams.toJSON()
		request.httpBody = requestJson.data(using: .utf8)
		// Send request
		let (data, _) = try await URLSession.shared.data(
			for: request
		)
		let response: TokenizeResponse = try JSONDecoder().decode(
			TokenizeResponse.self,
			from: data
		)
		return response.count
	}
	
	/// Function run for waiting for the server
	private func waitForServer(
        canReachRemoteServer: Bool
    ) async throws {
		// Check health
		guard process.isRunning else { return }
		// Init server health project
		let serverHealth = ServerHealth()
		await serverHealth.updateURL(
            self.url(
                "/health",
                openAiCompatiblePath: false,
                canReachRemoteServer: canReachRemoteServer,
                mustUseLocalServer: true
            ).url
		)
		await serverHealth.check()
		// Set check parameters
		var timeout = 30 // Timeout after 30 seconds
		let tick = 1 // Check every second
		while true {
			await serverHealth.check()
			let score = await serverHealth.score
			if score >= 0.25 { break }
			await serverHealth.check()
			try await Task.sleep(for: .seconds(tick))
			timeout -= tick
			if timeout <= 0 {
				Self.logger.error("llama-server did not respond in reasonable time")
				// Display error
				throw LlamaServerError.modelError
			}
		}
	}
	
	/// A structure modelling the inference server's response to a query for models
	struct AvailableModelsResponse: Codable {
		var data: [AvailableModel]
	}
	
	/// A structure modelling the models available on the inference server
	struct AvailableModel: Codable {
		var id: String
	}
	
	/// A structure modelling the health status response from the inference server
	struct HealthResponse: Codable {
		
		/// The status of the server, of type `String`
		var status: String
		/// A `Bool` representing whether the inference server is healthy
		var isHealthy: Bool { self.status == "ok" }
		
	}
	
	/// The message delta component of an update streamed from the inference server
	struct StreamMessage: Codable {
		
		/// The new token generated, decoded to type `String?`
		let content: String?
        
        /// The new reasoning token generated, decoded to type `String?`, for OpenRouter
        let reasoning: String?
        /// The new reasoning token generated, decoded to type `String?`, for Bailian
        let reasoning_content: String?
		
        /// The new reasoning token generated, if available
        var reasoningContent: String? {
            if let reasoning = self.reasoning,
                !reasoning.isEmpty {
                return reasoning
            } else if let reasoning_content = self.reasoning_content,
                      !reasoning_content.isEmpty {
                return reasoning_content
            } else {
                return nil
            }
        }
        
        /// A list of ``ToolCalls``, if it exists
        var tool_calls: [OpenAIToolCall]?
        
        struct OpenAIToolCall: Codable {
            
            var index: Int
            var id: String?
            var type: String?
            
            var function: Function
            
            struct Function: Codable {
                
                var name: String?
                var arguments: String?
                
                /// Function to get the corresponding function call
                public static func getFunctionCall(
                    name: String,
                    arguments: String
                ) -> (any DecodableFunctionCall)? {
                    // Try to init each function type
                    for function in DefaultFunctions.sortedFunctions {
                        // If function name matches
                        if function.name == name {
                            // Try to formulate arguments
                            let decoder: JSONDecoder = JSONDecoder()
                            // Convert to data
                            guard let data = arguments.data(
                                using: .utf8
                            ) else {
                                continue
                            }
                            // Decode
                            guard let params = try? decoder.decode(
                                function.paramsType.self,
                                from: data
                            ) else {
                                continue
                            }
                            // Init function call
                            return function.functionCallType.init(
                                name: function.name,
                                params: params
                            )
                        }
                    }
                    // If failed to init, return nil
                    return nil
                }
                
            }
            
        }
	}
	
	/// The choice component of an update streamed from the inference server
	struct StreamChoice: Codable {
		
		/// The new token generated, as a ``StreamMessage``
		let delta: StreamMessage
		/// The reason for finishing generation; returns `nil` if completion is not finished
		let finish_reason: String?
		
	}
	
	struct StreamResponse: Codable {
		
		let choices: [StreamChoice]
		let created: Double
		let usage: Usage?
		
	}
	
	struct Usage: Codable {
		
		let completion_tokens: Int?
		let prompt_tokens: Int?
		let total_tokens: Int?
		
	}
	
	struct StopResponse: Codable {
		
		let usage: Usage?
		
	}
	
	public struct CompleteResponse {
		
		var text: String
		var responseStartSeconds: Double
		var predictedPerSecond: Double?
		var modelName: String?
		/// A `Usage` object containing the number of tokens used, among other stats
		var usage: Usage?
		/// A `Bool` indicating whether a remote server was used
		var usedServer: Bool
		
        /// An array of ``FunctionCallRecord`` executed in the response
        var functionCallRecords: [FunctionCallRecord] = []
		/// A `Bool` representing if a function was called
		var containsFunctionCall: Bool {
            if let functionCalls = self.functionCalls,
               !functionCalls.isEmpty {
                return true
            }
            return false
		}
        /// Any function call in the response
        var functionCalls: [(any DecodableFunctionCall)]? {
            // Try to get block call first
            if let blockFunctionCalls = self.blockFunctionCalls,
                !blockFunctionCalls.isEmpty {
                return blockFunctionCalls
            }
            return self.inlineFunctionCalls
        }
        /// A function call in the response JSON
        var blockFunctionCalls: [(any DecodableFunctionCall)]?
        /// All inline function call found in the text
        var inlineFunctionCalls: [(any DecodableFunctionCall)]? {
            // Configure input
            let input: String = self.text.reasoningRemoved
            // Init decoder
            let decoder = JSONDecoder()
            // Decode
            return Self.decodeAllFunctionCalls(
                in: input,
                decoder: decoder
            )
        }
        
        /// Function to decode all function calls
        private static func decodeAllFunctionCalls(
            in input: String,
            decoder: JSONDecoder,
            searchStartIndex: String.Index? = nil
        ) -> [(any DecodableFunctionCall)]? {
            var results: [(any DecodableFunctionCall)] = []
            let startIdx = searchStartIndex ?? input.startIndex
            var searchStartIndex = startIdx
            // Look for every occurrence of '{'
            while let startIndex = input[searchStartIndex...].firstIndex(of: "{") {
                var braceCount = 0
                var currentIndex = startIndex
                var insideString = false
                var previousChar: Character? = nil
                var endIndex: String.Index? = nil
                // Attempt to balance the braces from here
                while currentIndex < input.endIndex {
                    let character = input[currentIndex]
                    // Toggle whether we're inside a string, ignoring escaped quotes
                    if character == "\"" && previousChar != "\\" {
                        insideString.toggle()
                    }
                    // Only process braces if we're not inside a string literal
                    if !insideString {
                        if character == "{" {
                            braceCount += 1
                        } else if character == "}" {
                            braceCount -= 1
                            if braceCount == 0 {
                                endIndex = currentIndex
                                break
                            }
                        }
                    }
                    previousChar = character
                    currentIndex = input.index(after: currentIndex)
                }
                // If we found matching braces, attempt to decode
                if let finalIndex = endIndex {
                    let jsonSubstring = input[startIndex...finalIndex]
                    let jsonString = String(jsonSubstring)
                    if let jsonData = jsonString.data(using: .utf8) {
                        // Try for all function types
                        for function in DefaultFunctions.sortedFunctions {
                            if let functionCall = function.functionCallType.parse(
                                from: jsonData,
                                using: decoder
                            ), jsonString.contains(
                                "\"\(function.name)\""
                            ) {
                                results.append(functionCall)
                                break
                            }
                        }
                    }
                    // Move searchStartIndex past this function call for the next iteration
                    searchStartIndex = input.index(after: finalIndex)
                } else {
                    // If we didn't find a matching '}', break the loop
                    break
                }
            }
            return results.isEmpty ? nil : results
        }
		
	}
	
	private struct TokenizeParams: Codable {
		
		let content: String
		
		/// Function to convert chat parameters to JSON
		public func toJSON() -> String {
			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			let jsonData = try? encoder.encode(self)
			return String(data: jsonData!, encoding: .utf8)!
		}
		
	}
	
	private struct TokenizeResponse: Codable {
		
		var tokens: [Int]?
		var count: Int {
			return self.tokens?.count ?? 0
		}
		
	}
	
	private struct CompletionParams: Codable {
		
		var prompt: String
		var max_tokens: Int
		var logprobs: Int = 1
		var temperature: Double = 0.0
		
	}

	private struct CompletionResponse: Codable {
		
		var completion: String? {
			return choices.first?.text
		}
		var logprob: Double? {
			return choices.first?.logprob
		}
		
		var choices: [Choice]
		
		struct Choice: Codable {
			
			var text: String
            
			var logprobs: Logprob
			var logprob: Double {
				return self.logprobs.content
					.map(keyPath: \.logprob)
					.reduce(0, +)
			}
			
			struct Logprob: Codable {
				
				var content: [Token]
                
			}
			
		}
		
	}
	
	public struct Token: Codable {
		
		var token: String
		var logprob: Double
		
	}
	
}

extension EventSource.DataTask: @unchecked Sendable {  }
