//
//  main.swift
//  llama-server-watchdog
//
//  Created by Bean John on 10/9/24.
//

import Foundation

/// Function for logging, used for debug
func log(_ line: String) {
	print("[watchdog]", line)
}

/// Function to terminate the server process
func terminateServerProcess(pid: Int32) {
	log("Terminating the server process with PID \(pid).")
	kill(pid, SIGTERM)
	log("Terminated server, exiting")
	exit(0)
}

/// Function to check the existence of the heartbeat file and detect if the main app is still alive
func checkHeartbeat(serverProcessPID: Int32) {
	let checkInterval: TimeInterval = 15.0
	
	while true {
		let fileHandle = FileHandle.standardInput
		if fileHandle.availableData.count > 0 {
			// If the file is recent, the main app is running; continue checking
			log("Main app is alive")
		} else {
			terminateServerProcess(pid: serverProcessPID)
		}
		
		// Wait for the next check interval before checking again
		Thread.sleep(forTimeInterval: checkInterval)
	}
}

/// Function to start the watchdog
func startWatchdog() {
	
	guard CommandLine.arguments.count == 2 else {
		print("Usage: server-watchdog <pid_to_kill>")
		return
	}
	
	guard let serverProcessPID = Int32(CommandLine.arguments[1]) else {
		log("Error: Invalid server process PID.")
		return
	}
	
	log("Watchdog process started.")
	checkHeartbeat(serverProcessPID: serverProcessPID)
}

/// Call the function to start the watchdog process
startWatchdog()

