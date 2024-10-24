//
//  SpeechRecognizer.swift
//  Sidekick
//
//  Created by Bean John on 10/19/24.
//

import Foundation
import AVFoundation
import Speech

public class PromptController: ObservableObject {
	
	@Published var isRecording: Bool = false
	@Published var prompt: String = ""
	@Published var audioLevel: Float = 0.0
	@Published var audioSamples: [Float] = []
	@Published var tempResources: [TemporaryResource] = []
	
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
							print("Microphone access denied")
						}
					}
				default:
					print("Speech recognition not authorized")
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
			self.isRecording = true
		}
	}
	
	public func stopRecording() {
		audioEngine.stop()
		audioEngine.inputNode.removeTap(onBus: 0)
		recognitionRequest?.endAudio()
		recognitionTask?.cancel()
		DispatchQueue.main.async {
			self.isRecording = false
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
		} catch {
			audioEngine.stop()
			audioEngine.reset()
		}
	}
	
	
	private func stopAudioEngine() {
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
					print("Speech recognition access granted.")
				case .denied, .restricted, .notDetermined:
					self.stopAudioEngine()
				@unknown default:
					fatalError("Unknown authorization status")
			}
		}
	}
	
	fileprivate func requestMicrophoneAccess() {
		AVCaptureDevice.requestAccess(for: .audio) { granted in
			if granted {
				print("Microphone access granted.")
			} else {
				self.stopRecording()
			}
		}
	}
}
