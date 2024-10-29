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
	
	init(modelPath: String, systemPrompt: String) {
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
	private var interrupted = false
	
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
	private func url(_ path: String) -> URL {
		URL(string: "\(scheme)://\(host):\(port)\(path)")!
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
		stopServer()
		// Initialize `llama-server` process
		process = Process()
		let startTime: Date = Date.now
		
		process.executableURL = Bundle.main.resourceURL?.appendingPathComponent("llama-server")
		
		let gpuLayers: Int = 99
		let processors: Int = ProcessInfo.processInfo.activeProcessorCount
		let threadsToUseIfGPU: Int = max(1, Int(ceil(Double(processors) / 3.0 * 2.0)))
		let threadsToUseIfCPU: Int = processors
		let threadsToUse: Int = InferenceSettings.useGPUAcceleration ? threadsToUseIfGPU : threadsToUseIfCPU
		
		process.arguments = [
			"--model", modelPath,
			"--threads", "\(threadsToUse)",
			"--threads-batch", "\(threadsToUse)",
			"--ctx-size", "\(contextLength)",
			"--port", port,
			"--n-gpu-layers", InferenceSettings.useGPUAcceleration ? "\(gpuLayers)" : "0"
		]
		
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
	public func stopServer() {
		if process.isRunning {
			process.terminate()
		}
		if monitor.isRunning {
			monitor.terminate()
		}
	}
	
	/// Function showing if connection was interrupted
	public func interrupt() async {
		if let eventSource, eventSource.readyState != .closed {
			await eventSource.close()
		}
		interrupted = true
	}
	
	/// Function to chat with the LLM
	func chat(
		messages: [Message.MessageSubset],
		similarityIndex: SimilarityIndex?,
		progressHandler: (@Sendable (String) -> Void)? = nil
	) async throws -> CompleteResponse {
		
		let start: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
		try await startServer()
		
		// Hit localhost for completion
		async let params = ChatParameters(
			messages: messages,
			systemPrompt: systemPrompt,
			similarityIndex: similarityIndex
		)
		var request = URLRequest(url: url("/v1/chat/completions"))
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
		request.setValue("keep-alive", forHTTPHeaderField: "Connection")
		request.httpBody = await params.toJSON().data(using: .utf8)
		// Use EventSource to receive server sent events
		eventSource = EventSource(request: request)
		eventSource!.connect()
		
		var response: String = ""
		var responseDiff: Double = 0.0
		var stopResponse: StopResponse?
		
		listenLoop: for await event in eventSource!.events {
			switch event {
				case .open:
					continue listenLoop
				case .error(let error):
					print("llama.cpp EventSource server error:", error.localizedDescription)
				case .message(let message):
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
							response.append(fragment)
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
		let cleanText: String = response
			.removeUnmatchedTrailingQuote()
		
		// Indicate response finished
		if responseDiff > 0 {
			// Call onFinish
			onFinish(text: response)
		}
		
		// Return info
		let tokens = stopResponse?.usage.completion_tokens ?? 0
		let generationTime: CFTimeInterval = CFAbsoluteTimeGetCurrent() - start - responseDiff
		return CompleteResponse(
			text: cleanText,
			responseStartSeconds: responseDiff,
			predictedPerSecond: Double(tokens) / generationTime,
			modelName: modelName,
			nPredicted: tokens
		)
	}
	
	/// Function executed when output finishes
	public func onFinish(text: String) {}
	
	/// Function run for waiting for the server
	private func waitForServer() async throws {
		guard process.isRunning else { return }
		interrupted = false
		serverErrorMessage = ""
		
		let serverHealth = ServerHealth()
		await serverHealth.updateURL(url("/health"))
		await serverHealth.check()
		
		var timeout = 60
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
	
	struct StreamMessage: Codable {
		let content: String?
	}
	
	struct StreamChoice: Codable {
		let delta: StreamMessage
		let finish_reason: String?
	}
	
	struct StreamResponse: Codable {
		let choices: [StreamChoice]
	}
	
	struct Usage: Codable {
		let completion_tokens: Int?
		let prompt_tokens: Int?
		let total_tokens: Int?
	}
	
	struct StopResponse: Codable {
		let choices: [StreamChoice]
		let usage: Usage
	}
	
	struct CompleteResponse {
		var text: String
		var responseStartSeconds: Double
		var predictedPerSecond: Double?
		var modelName: String?
		var nPredicted: Int?
	}
	
}
