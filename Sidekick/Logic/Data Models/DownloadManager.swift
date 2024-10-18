//
//  DownloadManager.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import OSLog
import SwiftUI

@MainActor
/// Controls the download of LLMs
class DownloadManager: NSObject, ObservableObject {
	
	/// Global instance of `DownloadManager`
	static var shared: DownloadManager = DownloadManager()
	
	/// Property for currently downloading URL session
	private var urlSession: URLSession!
	/// Published property for download progress
	@Published var tasks: [URLSessionTask] = []
	/// Published property for last update
	@Published var lastUpdatedAt = Date()
	/// Published property for whether the model was downloaded
	@Published var didFinishDownloadingModel: Bool = false
	
	override private init() {
		super.init()
		
		let config: URLSessionConfiguration = URLSessionConfiguration.background(
			withIdentifier: "com.pattonium.Sidekick.DownloadManager"
		)
		config.isDiscretionary = false
		
		// Warning: Make sure that the URLSession is created only once (if an URLSession still
		// exists from a previous download, it doesn't create a new URLSession object but returns
		// the existing one with the old delegate object attached)
		self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
		// Update lists of tasks for UI
		self.updateTasks()
	}
	
	/// Function to download the default large language model
	func downloadDefaultModel() {
		URL.verifyURL(
			urlPath: InferenceSettings.defaultModelUrlString
		) { isValid in
			if isValid {
				self.startDownload(
					url: InferenceSettings.defaultModelUrl
				)
			} else {
				self.startDownload(
					url: InferenceSettings.defaultModelMirrorUrl
				)
			}
		}
	}
	
	func startDownload(url: URL) {
		print("Starting download ", url)
		// Ignore download if it's already in progress
		if self.tasks.contains(where: {
			$0.originalRequest?.url == url
		}) {
			return
		}
		let task: URLSessionTask = urlSession.downloadTask(with: url)
		self.tasks.append(task)
		task.resume()
	}
	
	private func updateTasks() {
		self.urlSession.getAllTasks { tasks in
			DispatchQueue.main.async {
				self.tasks = tasks
				self.lastUpdatedAt = Date()
			}
		}
	}
}

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
	
	nonisolated func urlSession(
		_: URLSession,
		downloadTask: URLSessionDownloadTask,
		didWriteData _: Int64,
		totalBytesWritten _: Int64,
		totalBytesExpectedToWrite _: Int64
	) {
		DispatchQueue.main.async {
			let now: Date = Date()
			if self.lastUpdatedAt.timeIntervalSince(now) > 10 {
				self.lastUpdatedAt = now
			}
		}
	}
	
	nonisolated func urlSession(
		_: URLSession,
		task: URLSessionTask,
		didCompleteWithError error: Error?
	) {
		if let error = error {
			os_log("Download error: %@", type: .error, String(describing: error))
		} else {
			os_log("Task finished: %@", type: .info, task)
		}
		
		let taskId = task.taskIdentifier
		DispatchQueue.main.async {
			self.tasks.removeAll(where: { $0.taskIdentifier == taskId })
		}
	}
	
	nonisolated func urlSession(
		_: URLSession,
		downloadTask: URLSessionDownloadTask,
		didFinishDownloadingTo location: URL
	) {
		print("Download complete")
		// Move file to app resources
		let fileName = downloadTask.originalRequest?.url?.lastPathComponent ?? "defaultModel.gguf"
		let destinationURL = Settings.dirUrl.appending(
			path: fileName
		)
		// Remove if exists
		let fileManager = FileManager.default
		try? fileManager.removeItem(at: destinationURL)
		do {
			// Check if dir exists
			let folderExists: Bool = (
				try? Settings.dirUrl.checkResourceIsReachable()
			) ?? false
			// If not, fix
			if !folderExists {
				try fileManager.createDirectory(
					at: Settings.dirUrl,
					withIntermediateDirectories: false
				)
			}
			// Move the model to the directory
			try fileManager.moveItem(at: location, to: destinationURL)
			// Point to the model
			Settings.modelUrl = destinationURL
			Task.detached { @MainActor in
				self.didFinishDownloadingModel = true
			}
		} catch {
			os_log("FileManager copy error at %@ to %@ error: %@", type: .error, location.absoluteString, destinationURL.absoluteString, error.localizedDescription)
			return
		}
	}
		
}
