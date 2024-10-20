//
//  Extension+CGImage.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import AppKit
import Foundation

public extension CGImage {
	
	/// Function to save image to URL
	@MainActor
	func save(to url: URL) {
		let bitmapRep: NSBitmapImageRep = NSBitmapImageRep(cgImage: self)
		guard let imageData: Data = bitmapRep.representation(
			using: .png,
			properties: [:]
		) else {
			Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "Failed to save image.")
			)
			return
		}
		do {
			try imageData.write(to: url, options: .atomic)
		} catch {
			Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "Failed to save image.")
			)
			return
		}
	}
	
}
