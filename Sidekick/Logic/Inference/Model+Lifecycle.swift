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
        // Load model if needed
        let canReachRemoteServer: Bool = await self.remoteServerIsReachable()
        if !InferenceSettings.useServer || !canReachRemoteServer {
            try? await self.mainModelServer.startServer(
                canReachRemoteServer: canReachRemoteServer
            )
            try? await self.workerModelServer.startServer(
                canReachRemoteServer: canReachRemoteServer
            )
        }
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
        endpoint: String = InferenceSettings.endpoint
    ) async -> Bool {
        // Return false if server is unused
        if !InferenceSettings.useServer { return false }
        // Try to use cached result
        let lastPathChangeDate: Date = NetworkMonitor.shared.lastPathChange
        if self.lastRemoteServerCheck >= lastPathChangeDate {
            Self.logger.info("Using cached remote server reachability result")
            return self.wasRemoteServerAccessible
        }
        // Get last path change time
        // If using server, check connection on multiple endpoints
        let testEndpoints: [String] = [
            "/models",
            "/chat/completions"
        ]
        for testEndpoint in testEndpoints {
            let endpoint: String = endpoint.replacingSuffix(
                testEndpoint,
                with: ""
            ) + testEndpoint
            guard let endpointUrl: URL = URL(
                string: endpoint
            ) else {
                continue
            }
            if await endpointUrl.isAPIEndpointReachable(
                timeout: 3
            ) {
                // Cache result, then return
                self.wasRemoteServerAccessible = true
                self.lastRemoteServerCheck = Date.now
                Self.logger.info("Reached remote server at '\(endpoint, privacy: .public)'")
                return true
            }
        }
        // If fell through, cache and return false
        Self.logger.warning("Could not reach remote server at '\(endpoint, privacy: .public)'")
        self.wasRemoteServerAccessible = false
        self.lastRemoteServerCheck = Date.now
        return false
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


