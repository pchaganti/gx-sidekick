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
	///   - modelPath: The POSIX path linking to the model
	///   - systemPrompt: The system prompt passed to the model, which controls its behaviour
	init(
		modelPath: String,
		systemPrompt: String
	) {
		self.modelPath = modelPath
		self.systemPrompt = systemPrompt
		self.contextLength = InferenceSettings.contextLength
	}
	
	/// The IP address of the inference server's host
	private static let host: String = "127.0.0.1"
	/// The port where the inference server is accessible
	private static let port: String = "4579"
	/// The scheme through which the inference server is accessible
	private static let scheme: String = "http"
	
	/// A `Bool` indicating if the server is being started
	private var isStartingServer: Bool = false
	
	/// An `EventSource` instance opening a persistent connection to an HTTP server, which sends stream events
	private var eventSource: EventSource?
	///	An EventSource task handling connecting to the URLRequest and creating an event stream
	private var dataTask: EventSource.DataTask?
	
	/// The POSIX path to the LLM, of type `String`
	var modelPath: String?
	/// The name of the LLM, of type `String`
	var modelName: String {
		modelPath?.split(separator: "/").last?.map { String($0) }.joined() ?? "unknown"
	}
	
	/// The system prompt given to the chatbot
	var systemPrompt: String

	/// The context length used in chat completion
	var contextLength: Int
	
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
		_ path: String
	) async -> (
		url: URL,
		usingRemoteServer: Bool
	) {
		// Check endpoint
		let endpoint: String = InferenceSettings.endpoint
		let urlString: String
		let notUsingServer: Bool = await !Self.serverIsReachable(
			isLocal: false
		) || !InferenceSettings.useServer
		if notUsingServer {
			urlString = "\(Self.scheme)://\(Self.host):\(Self.port)\(path)"
		} else {
			urlString = "\(endpoint)\(path)"
		}
		return (URL(string: urlString)!, !notUsingServer)
	}
	
	/// Function to check if the remote server is reachable
	/// - Returns: A `Bool` indicating if the server can be reached
	public static func serverIsReachable(
		isLocal: Bool
	) async -> Bool {
		// Return false if server is unused
		if !InferenceSettings.useServer { return false }
		// Check endpoint
		let endpointUrl: URL = {
			if !isLocal {
				return URL(
					string: "\(InferenceSettings.endpoint)/health"
				)!
			} else {
				return URL(string: "http://\(Self.host):\(Self.port)/health")!
			}
		}()
		do {
			// Set timeout
			let config: URLSessionConfiguration = URLSessionConfiguration.default
			config.timeoutIntervalForRequest = 3
			config.timeoutIntervalForResource = 3
			let session: URLSession = URLSession(
				configuration: config
			)
			// Check server health
			let response: (data: Data, URLResponse) = try await session.data(
				from: endpointUrl
			)
			let decoder: JSONDecoder = JSONDecoder()
			let healthStatus: HealthResponse = try decoder.decode(
				HealthResponse.self,
				from: response.data
			)
			return healthStatus.isHealthy
		} catch {
			return false
		}
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
	public func startServer() async throws {
		// Signal beginning of server initialization
		self.isStartingServer = true
		// If server is running, exit
		guard !process.isRunning, let modelPath = self.modelPath else { return }
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
		
		var arguments: [String] = [
			"--model", modelPath,
			"--threads", "\(threadsToUse)",
			"--threads-batch", "\(threadsToUse)",
			"--ctx-size", "\(contextLength)",
			"--port", Self.port,
			"--flash-attn",
			"--gpu-layers", gpuLayersToUse
		]
		
		// If speculative decoding is used
		if let speculationModelUrl = InferenceSettings.speculativeDecodingModelUrl {
			if InferenceSettings.useSpeculativeDecoding {
				// Formulate arguments
				let draft: Int =  16
				let draftMin: Int = 6
				let draftPMin: Double = 0.75
				let speculativeDecodingArguments: [String] = [
					"--model-draft", speculationModelUrl.posixPath,
					"--gpu-layers-draft", "\(gpuLayersToUse)",
					"--draft-p-min", "\(draftPMin)",
					"--draft", "\(draft)",
					"--draft-min", "\(draftMin)"
				]
				// Append
				arguments += speculativeDecodingArguments
			}
		}
		
		process.arguments = arguments
		
		Self.logger.notice(
			"Starting llama.cpp server \(self.process.arguments!.joined(separator: " "))"
		)
		
		process.standardInput = FileHandle.nullDevice
		
		// To debug with server's output, comment these 2 lines to inherit stdout.
		process.standardOutput =  FileHandle.nullDevice
		process.standardError =  FileHandle.nullDevice
		
		try process.run()
		
		try await self.waitForServer()
		
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
		// If a server is used, exit
		if await Self.serverIsReachable(
			isLocal: false
		) && InferenceSettings.useServer {
			return
		}
		// Terminate processes
		if self.process.isRunning {
			self.process.terminate()
		}
		if self.monitor.isRunning {
			self.monitor.terminate()
		}
	}
	
	/// Function showing if connection was interrupted
	@EventSourceActor
	public func interrupt() async {
		if let dataTask = await self.dataTask, dataTask.readyState != .closed {
			dataTask.cancel()
		}
	}
	
	/// Function to get completion from the LLM
	/// - Parameters:
	///   - mode: The chat completion mode. This controls whether advanced features like resource lookup is used
	///   - messages: A list of prior messages
	///   - similarityIndex: A similarity index for resource lookup
	///   - progressHandler: A handler called after a new token is generated
	/// - Returns: The response returned from the inference server
	public func getCompletion(
		mode: Model.Mode,
		messages: [Message.MessageSubset],
		similarityIndex: SimilarityIndex? = nil,
		progressHandler: (@Sendable (String) -> Void)? = nil
	) async throws -> CompleteResponse {
		
		let rawUrl = await self.url("/v1/chat/completions")
		
		let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
		
		// Start server if remote server is not used & local server is inactive
		let serverIsReachable: Bool = await Self.serverIsReachable(
			isLocal: true
		)
		if !rawUrl.usingRemoteServer && !serverIsReachable {
			try await startServer()
		}
		
		// Formulate parameters
		async let params = {
			switch mode {
				case .chat:
					return await ChatParameters(
						messages: messages,
						systemPrompt: self.systemPrompt,
						useInterpreter: true,
						similarityIndex: similarityIndex
					)
				case .contextAwareAgent:
					return await ChatParameters(
						messages: messages,
						systemPrompt: self.systemPrompt,
						similarityIndex: similarityIndex
					)
				case .default:
					return await ChatParameters(
						messages: messages,
						systemPrompt: self.systemPrompt
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
			request.setValue("nil", forHTTPHeaderField: "ngrok-skip-browser-warning")
		}
		let requestJson: String = await params.toJSON()
		request.httpBody = requestJson.data(using: .utf8)
		
		// Use EventSource to receive server sent events
		self.eventSource = EventSource(
			timeoutInterval: 6000 // Timeout after 100 minutes, enough for even reasoning models
		)
		self.dataTask = await eventSource!.dataTask(
			for: request
		)
		
		var pendingMessage: String = ""
		var responseDiff: Double = 0.0
		var stopResponse: StopResponse? = nil
		
		listenLoop: for await event in await dataTask!.events() {
			switch event {
				case .open:
					continue listenLoop
				case .error(let error):
					Self.logger.error(
						"llama.cpp EventSource server error: \(error)"
					)
					if !isStartingServer {
						try await self.startServer()
					}
				case .event(let message):
					// Parse json in message.data string
					// Then, print the data.content value and append it to response
					if let data = message.data?.data(using: .utf8) {
						let decoder = JSONDecoder()
						do {
							let responseObj: StreamResponse = try decoder.decode(
								StreamResponse.self,
								from: data
							)
							let fragment: String = responseObj.choices.map({
								$0.delta.content ?? ""
							}).joined()
							pendingMessage.append(fragment)
							progressHandler?(fragment)
							if responseDiff == 0 {
								responseDiff = CFAbsoluteTimeGetCurrent() - start
							}
							if responseObj.choices[0].finish_reason != nil {
								do {
									stopResponse = try decoder.decode(StopResponse.self, from: data)
									break listenLoop
								} catch {
									print("Error decoding stopResponse, listenLoop will continue", error as Any, data)
								}
							}
						} catch {
							Self.logger.error("Error decoding response object \(error as Any)")
							Self.logger.error("responseObj: \(String(decoding: data, as: UTF8.self))")
						}
					}
				case .closed:
					Self.logger.notice("llama.cpp EventSource closed")
					break listenLoop
			}
		}
		// Adding a trailing quote or space is a common mistake with the smaller model output
		let cleanText: String = pendingMessage
			.removeUnmatchedTrailingQuote()
		// Indicate response finished
		if responseDiff > 0 {
			// Call onFinish
			onFinish(text: cleanText)
		}
		// Return info
		let tokens = stopResponse?.usage.completion_tokens ?? 0
		let generationTime: CFTimeInterval = CFAbsoluteTimeGetCurrent() - start - responseDiff
		return CompleteResponse(
			text: cleanText,
			responseStartSeconds: responseDiff,
			predictedPerSecond: Double(tokens) / generationTime,
			modelName: modelName,
			usage: stopResponse?.usage,
			usedServer: rawUrl.usingRemoteServer
		)
	}
	
	/// Function executed when output finishes
	/// - Parameter text: The output generated by the LLM
	public func onFinish(text: String) {}
	
	/// Function to get number of tokens in a piece of text
	/// - Parameter text: The text for which the number of tokens is calculated
	/// - Returns: The number of tokens in the text
	public func tokenCount(
		in text: String
	) async throws -> Int {
		// Get url of endpoint
		let rawUrl = await self.url("/tokenize")
		// Formulate request
		var request = URLRequest(
			url: rawUrl.url
		)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("keep-alive", forHTTPHeaderField: "Connection")
		if rawUrl.usingRemoteServer {
			request.setValue("nil", forHTTPHeaderField: "ngrok-skip-browser-warning")
		}
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
	private func waitForServer() async throws {
		// Check health
		guard process.isRunning else { return }
		// Init server health project
		let serverHealth = ServerHealth()
		await serverHealth.updateURL(url("/health").url)
		await serverHealth.check()
		// Set check parameters
		var timeout = 30
		let tick = 1
		while true {
			await serverHealth.check()
			let score = await serverHealth.score
			if score >= 0.25 { break }
			await serverHealth.check()
			if !process.isRunning {
				Self.logger.error("llama-server is not running")
				// Attempt to revive server
				try? await self.startServer()
				throw LlamaServerError.modelError
			}
			try await Task.sleep(for: .seconds(tick))
			timeout -= tick
			if timeout <= 0 {
				Self.logger.error("llama-server did not respond in reasonable time")
				// Attempt to revive server
				try? await self.startServer()
				throw LlamaServerError.modelError
			}
		}
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
		
	}
	
	struct Usage: Codable {
		
		let completion_tokens: Int?
		let prompt_tokens: Int?
		let total_tokens: Int?
		
	}
	
	struct StopResponse: Codable {
		
		let usage: Usage
		
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
		
		/// A `Bool` representing whether a JavaScript code interpreter was used
		var usedCodeInterpreter: Bool = false
		/// A `String` containing the JavaScript code that was executed, if any
		var jsCode: String?
		
		/// A `Bool` representing if code interpreter was used
		var containsInterpreterCall: Bool {
			return self.javascriptCodeRange != nil
		}
		
		/// The `Range<String.Index>` where the JavaScript code is located
		var javascriptCodeRange: Range<String.Index>? {
			// Get range of last instance of `run_javascript(code: "`
			guard let startOfCallRange = self.text.range(
				of: "run_javascript(code: \"",
				options: .backwards
			) else {
				return nil
			}
			// Ensure searching within valid bounds
			let searchRange = startOfCallRange.upperBound..<self.text.endIndex
			// Get range of last instance of `")`
			guard let endOfCallRange = self.text.range(
				of: "\")",
				range: searchRange
			) else {
				return nil
			}
			return startOfCallRange.upperBound..<endOfCallRange.lowerBound
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
	
}

extension EventSource.DataTask: @unchecked Sendable {  }
