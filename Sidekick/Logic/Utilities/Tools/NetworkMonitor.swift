//
//  NetworkMonitor.swift
//  Sidekick
//
//  Created by John Bean on 3/12/25.
//

import Foundation
import Network

/// Monitors network path changes and records the timestamp of the last change
public final class NetworkMonitor {
	
	/// The shared singleton instance of `NetworkMonitor`
	static let shared = NetworkMonitor()
	
	/// The underlying `NWPathMonitor` responsible for monitoring the network path
	private let monitor: NWPathMonitor
	
	/// The queue on which the `NWPathMonitor` runs
	private let queue: DispatchQueue
	
	/// The timestamp of the last network path change, updated every time the network path changes
	private(set) var lastPathChange: Date = .now
	
	/// Initializer
	private init() {
		self.monitor = NWPathMonitor()
		self.queue = DispatchQueue(label: "net-monitor")
		// Handle network path changes
		self.monitor.pathUpdateHandler = { [weak self] path in
			guard let self = self else { return }
			// Update the timestamp when the path changes
			self.lastPathChange = Date.now
			// Cache network call result
			Task {
				let _ = await Model.shared.llama.remoteServerIsReachable()
			}
		}
		// Start monitor
		self.startMonitoring()
	}
	
	/// Function to start monitoring network path changes
	public func startMonitoring() {
		monitor.start(queue: queue)
	}
	
	/// Function to stop monitoring network path changes
	public func stopMonitoring() {
		monitor.cancel()
	}
	
}
