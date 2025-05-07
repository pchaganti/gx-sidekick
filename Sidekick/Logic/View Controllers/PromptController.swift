//
//  SpeechRecognizer.swift
//  Sidekick
//
//  Created by Bean John on 10/19/24.
//

import AVFoundation
import Foundation
import OSLog
import Speech
import SwiftUI
import ImagePlayground

@MainActor
public class PromptController: ObservableObject, DropDelegate {
	
	/// A `Logger` object for the `PromptController` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: PromptController.self)
	)
	
	@Published var sentConversation: Conversation? = nil
	@Published var sentExpertId: UUID? = nil
	
	@Published var isGeneratingImage: Bool = false
	@Published var imageConcept: String? = nil
	
    @Published var useReasoning: Bool = Model.shared.selectedModel?.isReasoningModel ?? true
    @Published var didManuallyToggleReasoning: Bool = false
    
	@Published var useWebSearch: Bool = false
    @Published var selectedSearchState: SearchState = .search
    
    @Published var useFunctions: Bool = Settings.useFunctions
	
    @Published var prompt: String = ""
    @Published var insertionPoint: Int = 0
    @FocusState public var isFocused: Bool
    
    @Published var isRecording: Bool = false
	@Published var audioLevel: Float = 0.0
	@Published var audioSamples: [Float] = []
	
	/// A list of resources temporarily passed to the chatbot, of type ``[TemporaryResource]``
	@Published var tempResources: [TemporaryResource] = []
	
	/// A `Bool` representing whether resources will be passed to the chatbot
	public var hasResources: Bool {
		!tempResources.isEmpty
	}
	
	private var audioEngine: AVAudioEngine = AVAudioEngine()
	private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
	private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
	private var recognitionTask: SFSpeechRecognitionTask?
	
	func toggleRecording() {
		if isRecording {
			stopRecording()
		} else {
			requestSpeechRecognitionAccess()
			requestMicrophoneAccess()
			checkPermissionsAndStartRecording()
		}
	}
	
	private func checkPermissionsAndStartRecording() {
		SFSpeechRecognizer.requestAuthorization { authStatus in
			switch authStatus {
				case .authorized:
					AVCaptureDevice.requestAccess(for: .audio) { granted in
						if granted {
							self.startRecording()
						} else {
							Self.logger.warning("Microphone access denied")
						}
					}
				default:
					Self.logger.warning("Speech recognition not authorized")
			}
		}
	}
	
	// MARK: - Start/stop recording
	
	private func startRecording() {
		guard !audioEngine.isRunning else {
			return
		}
		resetRecognitionTaskIfNeeded()
		createRecognitionRequest()
		setupRecognitionTask()
		startAudioEngine()
		DispatchQueue.main.sync {
            withAnimation(.linear) {
                self.isRecording = true
            }
		}
	}
	
	public func stopRecording() {
		// Exit if not recording
		if !self.isRecording { return }
		// Stop recording
		audioEngine.stop()
		audioEngine.inputNode.removeTap(onBus: 0)
		recognitionRequest?.endAudio()
		recognitionTask?.cancel()
		DispatchQueue.main.async {
            withAnimation(.linear) {
                self.isRecording = false
            }
		}
	}
	
	// MARK: - Speech recognition tasks (reset, create, setup & handle recognition results)
	
	private func resetRecognitionTaskIfNeeded() {
		if recognitionTask != nil {
			recognitionTask?.cancel()
			recognitionTask = nil
		}
	}
	
	private func createRecognitionRequest() {
		recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
		guard let recognitionRequest = recognitionRequest else {
			fatalError("Unable to create recognition request")
		}
		recognitionRequest.shouldReportPartialResults = true
	}
	
	private func setupRecognitionTask() {
		guard let recognitionRequest = recognitionRequest else { return }
		recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
			if let result = result {
				DispatchQueue.main.async {
					let resultString: String = result.bestTranscription.formattedString
					if !resultString.isEmpty {
						self.prompt = resultString
					}
				}
			}
			if error != nil || result?.isFinal == true {
				self.stopAudioEngine()
			}
		}
	}
	
	// MARK: - Audio engine control (configures the audio engine with hardware format and starts capturing audio)
	
	private func startAudioEngine() {
		let inputNode = audioEngine.inputNode
		let hwFormat = inputNode.inputFormat(forBus: 0)
		inputNode.removeTap(onBus: 0)
		inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { buffer, when in
			self.recognitionRequest?.append(buffer)
			self.detectAudioLevel(buffer: buffer)
		}
		do {
			try audioEngine.start()
			Self.logger.notice("Started audio engine")
		} catch {
			audioEngine.stop()
			audioEngine.reset()
			Self.logger.warning("Failed to start audio engine")
		}
	}
	
	
	private func stopAudioEngine() {
		Self.logger.notice("Stopping audio engine")
		audioEngine.stop()
		audioEngine.inputNode.removeTap(onBus: 0)
		recognitionRequest = nil
		recognitionTask = nil
	}
	
	// MARK: - Audio Level Detection
	
	private func detectAudioLevel(buffer: AVAudioPCMBuffer) {
		guard let channelData = buffer.floatChannelData else { return }
		let channelDataValue = channelData.pointee
		let channelDataArray = stride(from: 0,
									  to: Int(buffer.frameLength),
									  by: buffer.stride).map { channelDataValue[$0] }
		
		let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
		let avgPower: Float = 20 * log10(rms)
		
		DispatchQueue.main.async {
			self.audioLevel = (avgPower + 160) / 160
		}
	}
	
	// MARK: - Permission requests
	
	fileprivate func requestSpeechRecognitionAccess() {
		SFSpeechRecognizer.requestAuthorization { authStatus in
			switch authStatus {
				case .authorized:
					Self.logger.info("Speech recognition access granted.")
				case .denied, .restricted, .notDetermined:
					Self.logger.info("Speech recognition access is \(authStatus.rawValue,privacy: .public).")
					self.stopAudioEngine()
				@unknown default:
					fatalError("Unknown authorization status")
			}
		}
	}
	
	fileprivate func requestMicrophoneAccess() {
		AVCaptureDevice.requestAccess(
			for: .audio
		) { granted in
			if granted {
				Self.logger.notice("Microphone access granted.")
			} else {
				self.stopRecording()
			}
		}
	}
	
	/// Function to validate dropped item
	public func validateDrop(info: DropInfo) -> Bool {
		return info.hasItemsConforming(to: ["public.file-url"])
	}
	
	/// Function to handle drop
	public func performDrop(info: DropInfo) -> Bool {
		for itemProvider in info.itemProviders(for: ["public.file-url"]) {
			itemProvider.loadItem(
				forTypeIdentifier: "public.file-url",
				options: nil
			) { (item, error) in
				if let data = item as? Data {
					Task { @MainActor in
						await self.addFile(data)
					}
				}
			}
		}
		return true
	}
	
	/// Function to add a file from decoded URL
	public func addFile(_ data: Data) async {
		if let url = URL(
			dataRepresentation: data,
			relativeTo: nil
		) {
			await self.addFile(url)
		}
	}
	
	/// Function to add a file from URL
	public func addFile(_ url: URL) async {
		// Add temp resource if needed
		if self.tempResources.map(
			\.url
		).contains(url) {
			return
		}
		withAnimation(.linear) {
			self.tempResources.append(
				TemporaryResource(
					url: url
				)
			)
			Self.logger.notice("Added temporary resource: \(url, privacy: .public)")
		}
	}
	
}
