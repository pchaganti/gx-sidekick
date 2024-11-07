//
//  Extension+View.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

extension View {
	
	@ViewBuilder public func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
		if conditional {
			content(self)
		} else {
			self
		}
	}
	
	public func glow(color: Color = .red, radius: CGFloat = 20, blurred: Bool = true) -> some View {
		return Group {
			if blurred {
				self
					.overlay(self.blur(radius: radius / 6))
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
			} else {
				self
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
					.shadow(color: color, radius: radius / 3)
			}
		}
	}
	
	/// Function to generate and save conversation as an image
	public func generatePng() {
		// Select path
		guard var destination: URL = try? FileManager.selectFile(
			dialogTitle: String(localized: "Select a Save Location"),
			canSelectFiles: false,
			canSelectDirectories: true,
			allowMultipleSelection: false,
			persistPermissions: false
		).first else {
			return
		}
		let filename: String = Date.now.ISO8601Format()
		destination = destination.appendingPathComponent("\(filename).png")
		// Render and save
		let renderer: ImageRenderer = ImageRenderer(
			content: self
		)
		renderer.scale = 2.0
		guard let cgImage: CGImage = renderer.cgImage else {
			Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "Failed to render image.")
			)
			return
		}
		cgImage.save(to: destination)
	}
	
	/// Function to generate png data
	public func generatePngData() -> Data? {
		// Render and save
		let renderer: ImageRenderer = ImageRenderer(
			content: self
		)
		renderer.scale = 2.0
		guard let cgImage: CGImage = renderer.cgImage else {
			Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "Failed to render image.")
			)
			return nil
		}
		// Convert to data
		let bitmapRep: NSBitmapImageRep = NSBitmapImageRep(
			cgImage: cgImage
		)
		guard let data: Data = bitmapRep.representation(
			using: .png, properties: [:]
		) else {
			Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "Failed to convert image to data.")
			)
			return nil
		}
		return data
	}
	
}
