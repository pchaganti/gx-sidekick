//
//  HuggingFaceModel.swift
//  Sidekick
//
//  Created by Bean John on 11/3/24.
//

import Foundation

public struct HuggingFaceModel: Codable {
	
	/// Initializer
	init(
		urlString: String,
		minRam: Int,
		minGpu: Int,
		mmluScore: Float
	) {
		self.urlString = urlString
		self.minRam = minRam
		self.minGpu = minGpu
		self.mmluScore = mmluScore
	}
	
	/// The URL of the model's in type `String`
	public var urlString: String
	
	/// The minimum RAM needed for the model, in type 	`Int`
	public var minRam: Int
	
	/// The minimum GPU core count needed, in type `Int`
	public var minGpu: Int
	
	/// Score in the MMLU benchmark, in type `Float`
	public var mmluScore: Float
	
	/// The URL of the model's of type `URL`
	public var url: URL {
		return URL(string: urlString)!
	}
	
	/// /// The URL of the model's mirror of type `URL`
	public var mirrorUrl: URL {
		let mirrored: String = self.urlString.replacingOccurrences(
			of: "huggingface.co",
			with: "hf-mirror.com"
		)
		return URL(string: mirrored)!
	}
	
	/// The name of the model of type `String`
	public var name: String {
		return self.url.deletingPathExtension().lastPathComponent
	}
	
	/// A function to indicate whether the device can run the model
	/// - Parameters:
	///   - unifiedMemorySize: The amount of RAM in the device, in type `Int`
	///   - gpuCoreCount: The number of GPU cores in the device, in type `Int`
	/// - Returns: A `Bool` indicating whether the device can run the model
	public func canRun(
		unifiedMemorySize: Int? = nil,
		gpuCoreCount: Int? = nil
	) -> Bool {
		let unifiedMemorySize: Int = unifiedMemorySize ?? self.unifiedMemorySize
		let gpuCoreCount: Int = gpuCoreCount ?? self.gpuCoreCount
		let ramPass: Bool = unifiedMemorySize >= self.minRam
		let gpuPass: Bool = gpuCoreCount >= self.minGpu
		return ramPass && gpuPass
	}
	
	/// The device's unified memory in GB, of type `Int`
	private var unifiedMemorySize: Int {
		let memory: Double = Double(ProcessInfo.processInfo.physicalMemory)
		let memoryGb: Int = Int(memory / pow(2,30))
		return memoryGb
	}
	
	/// The device's GPU core count, of type `Int`
	private var gpuCoreCount: Int {
		guard let device: GPUInfoDevice = try? .init() else {
			return .maximum
		}
		return device.coreCount
	}
	
}
