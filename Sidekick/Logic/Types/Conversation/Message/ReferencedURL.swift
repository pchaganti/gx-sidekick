//
//  ReferencedURL.swift
//  Sidekick
//
//  Created by Bean John on 10/13/24.
//

import AppKit
import Foundation
import FSKit_macOS
import SwiftUI
import UniformTypeIdentifiers

public struct ReferencedURL: Codable, Equatable, Hashable {
	
	/// URL referenced in a response
	public var url: URL
	
	/// Computed property returning displayed name
	public var displayName: String {
		if self.url.isWebURL {
			return self.url.host(percentEncoded: false) ??
			self.url.absoluteString
		}
		return self.url.lastPathComponent
	}
	
	/// Computed property returning a view that links to the reference
	@MainActor
	public var openButton: some View {
		Button {
			self.open()
		} label: {
			HStack {
				Image(systemName: self.url.isWebURL ? "globe" : "document")
				Text(displayName)
					.font(.body)
			}
			.padding(4)
			.padding(.horizontal, 2)
			.background {
				Capsule()
					.stroke(lineWidth: 1)
			}
			.draggable(self.url)
		}
		.buttonStyle(.plain)
		.foregroundStyle(Color.secondary)
		.contextMenu {
			if !self.url.isWebURL {
				Button {
					self.showInFinder()
				} label: {
					Text("Show in Finder")
				}
			}
		}
	}
	
	/// Function to open the URL
	@MainActor
	private func open() {
		// Correct url
		var url: URL = self.url
		if !url.isWebURL {
			url = URL(fileURLWithPath: self.url.posixPath)
		}
		let result: Bool = NSWorkspace.shared.open(url)
		if !result {
			let _ = Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "Failed to open \(self.url.absoluteString)")
			)
		}
	}
	
	/// Function to open the URL's enclosing folder
	@MainActor
	private func showInFinder() {
		// Check if
		if self.url.isWebURL {
			return
		}
		let url: URL = URL(
			fileURLWithPath: self.url.posixPath
		)
		FileManager.showItemInFinder(url: url)
	}
	
}
