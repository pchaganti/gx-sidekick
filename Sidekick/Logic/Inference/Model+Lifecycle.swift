//
//  Model+Lifecycle.swift
//  Sidekick
//
//  Created by Bean John on 9/22/24.
//

import Foundation
import OSLog

extension Model {
    
    // MARK: - Prompt Configuration
    
    public func setSystemPrompt(
        _ systemPrompt: String
    ) async {
        self.systemPrompt = systemPrompt
        await self.mainModelServer.setSystemPrompt(systemPrompt)
    }
    
    public func refreshModel() async {
        // Restart servers if needed
        await self.stopServers()
        self.mainModelServer = LlamaServer(
            modelType: .regular,
            systemPrompt: self.systemPrompt
        )
        self.workerModelServer = LlamaServer(
            modelType: .worker
        )
        let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
        self.wasRemoteServerAccessible = canReachRemoteServer
    }
    
    // MARK: - Token Counting
    
    public func countTokens(
        in text: String
    ) async -> Int? {
        let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
        return try? await self.mainModelServer.tokenCount(
            in: text,
            canReachRemoteServer: canReachRemoteServer
        )
    }
    
    // MARK: - Remote Reachability
    
    public func remoteServerIsReachable(
        endpoint: String = InferenceSettings.endpoint,
        timeout: TimeInterval = 1.5
    ) async -> Bool {
        // Return false if server is unused
        if !InferenceSettings.useServer { return false }
        // Try to use cached result
        let lastPathChangeDate: Date = NetworkMonitor.shared.lastPathChange
        if self.lastRemoteServerCheck >= lastPathChangeDate {
            Self.logger.info("Using cached remote server reachability result")
            return self.wasRemoteServerAccessible
        }
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEndpoint.isEmpty else {
            self.wasRemoteServerAccessible = false
            self.lastRemoteServerCheck = Date.now
            return false
        }
        let sanitizedBase = trimmedEndpoint.hasSuffix("/") ? String(trimmedEndpoint.dropLast()) : trimmedEndpoint
        let normalizedBase = sanitizedBase.replacingSuffix("/chat/completions", with: "")
        let testPaths: [String] = [
            "models",
            "chat/completions"
        ]
        let reachable: Bool = await withTaskGroup(of: Bool.self) { group in
            for path in testPaths {
                group.addTask {
                    let urlString: String
                    if normalizedBase.hasSuffix("/") {
                        urlString = normalizedBase + path
                    } else {
                        urlString = "\(normalizedBase)/\(path)"
                    }
                    guard let endpointUrl = URL(string: urlString) else {
                        return false
                    }
                    return await endpointUrl.isAPIEndpointReachable(
                        timeout: timeout
                    )
                }
            }
            var success: Bool = false
            while let result = await group.next() {
                if result {
                    success = true
                    group.cancelAll()
                    break
                }
            }
            return success
        }
        self.wasRemoteServerAccessible = reachable
        self.lastRemoteServerCheck = Date.now
        if reachable {
            Self.logger.info("Reached remote server at '\(normalizedBase, privacy: .public)'")
        } else {
            Self.logger.warning("Could not reach remote server at '\(normalizedBase, privacy: .public)'")
        }
        return reachable
    }
    
    // MARK: - Server Lifecycle
    
    func stopServers() async {
        await self.mainModelServer.stopServer()
        await self.workerModelServer.stopServer()
        self.status = .cold
    }
    
    func interrupt() async {
        if !self.status.isWorking {
            return
        }
        await self.mainModelServer.interrupt()
        self.agent = nil
        self.pendingMessage = nil
        self.status = .ready
    }
    
}


