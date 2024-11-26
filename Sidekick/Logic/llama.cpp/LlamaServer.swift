//
//  LlamaServer.swift
//  Sidekick
//
//  Created by Bean John on 10/9/24.
//

import EventSource
import Foundation
import FSKit_macOS
import SimilaritySearchKit

public actor LlamaServer {
	
	init(
		modelPath: String,
		systemPrompt: String
	) {
		self.modelPath = modelPath
		self.systemPrompt = systemPrompt
		self.contextLength = InferenceSettings.contextLength
	}
	
	private let host: String = "127.0.0.1"
	private let port: String = "4579"
	private let scheme: String = "http"
	
	private var serverUp = false
	private var serverErrorMessage = ""
	
	private var eventSource: EventSource?
	private var dataTask: EventSource.DataTask?
	
	var modelPath: String?
	var modelName: String {
		modelPath?.split(separator: "/").last?.map { String($0) }.joined() ?? "unknown"
	}
	
	var systemPrompt: String
	func getSystemPrompt() -> String {
		systemPrompt
	}
	
	var contextLength: Int
	
	/// Property for `llama-server-watchdog` process
	private var monitor: Process = Process()
	/// Property for `llama-server` process
	private var process: Process = Process()
	
	/// Function to get path to llama-server
	private func url(_ path: String) async -> (
		url: URL,
		usingRemoteServer: Bool
	) {
		// Check endpoint
		let endpoint: String = InferenceSettings.endpoint
		let urlString: String
		let notUsingServer: Bool = await !Self.remoteServerIsReachable() || !InferenceSettings.useServer
		if notUsingServer {
			 urlString = "\(scheme)://\(host):\(port)\(path)"
		} else {
			urlString = "\(endpoint)\(path)"
		}
		return (URL(string: urlString)!, !notUsingServer)
	}
	
	/// Function to check if the remote server is reachable
	public static func remoteServerIsReachable() async -> Bool {
		// Return false if server is unused
		if !InferenceSettings.useServer { return false }
		// Check endpoint
		let endpointUrl: URL = URL(
			string: "\(InferenceSettings.endpoint)/health"
		)!
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
	private func startAppMonitor(serverPID: pid_t) throws {
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
		print("Started monitor for server with PID \(serverPID)")
	}
	
	/// Function to start the `llama-server` process
	private func startServer() async throws {
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
			"--port", port,
			"--flash-attn", 
			"--n-gpu-layers", gpuLayersToUse
		]
		
		// If speculative decoding is used
		if let speculationModelUrl = InferenceSettings.speculativeDecodingModelUrl {
			if InferenceSettings.useSpeculativeDecoding {
				// Formulate arguments
				let draft: Int =  15
				let draftMin: Int =  3
				let speculativeDecodingArguments: [String] = [
					"-md", speculationModelUrl.posixPath,
					"-ngld", "\(gpuLayersToUse)",
					"--draft", "\(draft)",
					"--draft-min", "\(draftMin)"
				]
				// Append
				arguments += speculativeDecodingArguments
			}
		}
		
		process.arguments = arguments
		
		print("Starting llama.cpp server \(process.arguments!.joined(separator: " "))")
		
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
	}
	
	/// Function to stop the `llama-server` process
	public func stopServer() async {
		// If a server is used, exit
		if await Self.remoteServerIsReachable() && InferenceSettings.useServer {
			return
		}
		// Terminate processes
		if process.isRunning {
			process.terminate()
		}
		if monitor.isRunning {
			monitor.terminate()
		}
	}
	
	/// Function showing if connection was interrupted
	@EventSourceActor
	public func interrupt() async {
		if let dataTask = await self.dataTask, dataTask.readyState != .closed {
			dataTask.cancel()
		}
	}
	
	/// Function to chat with the LLM
	/// Function to chat with the LLM
	func chat(
		messages: [Message.MessageSubset],
		similarityIndex: SimilarityIndex?,
		progressHandler: (@Sendable (String) -> Void)? = nil
	) async throws -> CompleteResponse {
		
		let rawUrl = await self.url("/v1/chat/completions")
		
		let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
		if !rawUrl.usingRemoteServer {
			try await startServer()
		}
		
		// Hit localhost for completion
		async let params = ChatParameters(
			messages: messages,
			systemPrompt: systemPrompt,
			similarityIndex: similarityIndex
		)
		
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
		request.httpBody = await params.toJSON().data(using: .utf8)
		
		// Use EventSource to receive server sent events
		self.eventSource = EventSource(
			timeoutInterval: 60
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
					print("llama.cpp EventSource server error:", error.localizedDescription)
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
							print("Error decoding responseObj", error as Any)
							print("responseObj: \(String(decoding: data, as: UTF8.self))")
						}
					}
				case .closed:
					print("llama.cpp EventSource closed")
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
			nPredicted: tokens,
			usedServer: rawUrl.usingRemoteServer
		)
	}
	
	/// Function executed when output finishes
	public func onFinish(text: String) {}
	
	/// Function run for waiting for the server
	private func waitForServer() async throws {
		// Check health
		guard process.isRunning else { return }
		serverErrorMessage = ""
		
		let serverHealth = ServerHealth()
		await serverHealth.updateURL(url("/health").url)
		await serverHealth.check()
		
		var timeout = 30
		let tick = 1
		while true {
			await serverHealth.check()
			let score = await serverHealth.score
			if score >= 0.25 { break }
			await serverHealth.check()
			if !process.isRunning {
				throw LlamaServerError.modelError(modelName: modelName)
			}
			
			try await Task.sleep(for: .seconds(tick))
			timeout -= tick
			if timeout <= 0 {
				throw LlamaServerError.modelError(modelName: modelName)
			}
		}
	}
	
	struct HealthResponse: Codable {
		
		var status: String
		var isHealthy: Bool { self.status == "ok" }
		
	}
	
	struct StreamMessage: Codable {
		
		let content: String?
		
	}
	
	struct StreamChoice: Codable {
		
		let delta: StreamMessage
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
	
	struct CompleteResponse {
		
		var text: String
		var responseStartSeconds: Double
		var predictedPerSecond: Double?
		var modelName: String?
		var nPredicted: Int?
		var usedServer: Bool
		
	}
	
}

extension EventSource.DataTask: @unchecked Sendable {  }
