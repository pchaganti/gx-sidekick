//
//  ModelRowView.swift
//  Sidekick
//
//  Created by Bean John on 11/8/24.
//

import FSKit_macOS
import SwiftUI

struct ModelRowView: View {
	
	@EnvironmentObject private var modelManager: ModelManager
	
	@Binding var modelFile: ModelManager.ModelFile
	@Binding var modelUrl: URL?
	@State var isHovering: Bool = false
	
	var isSelected: Bool {
		return modelFile.url == modelUrl
	}
	
    var body: some View {
		HStack {
			selectedIndicator
			Text(modelFile.name)
			Spacer()
			button
		}
		.onTapGesture {
			self.select()
		}
		.onHover { isHovering in
			self.isHovering = isHovering
		}
		.contextMenu {
			openButton
		}
    }
	
	var openButton: some View {
		Button {
			FileManager.showItemInFinder(url: modelFile.url)
		} label: {
			Text("Show in Finder")
		}
	}
	
	var selectedIndicator: some View {
		Circle()
			.fill(
				self.isSelected ? Color.green : Color.clear
			)
			.frame(width: 5, height: 5)
	}
	
	var button: some View {
		Group {
			if !isSelected && isHovering {
				Button {
					self.modelManager.delete(self.modelFile)
				} label: {
					Label(
						"Delete",
						systemImage: "trash"
					)
					.labelStyle(.iconOnly)
					.foregroundStyle(.red)
				}
				.buttonStyle(.plain)
			}
		}
	}
	
	/// Function to select model
	private func select() {
		// Update variables
		Settings.modelUrl = self.modelFile.url
		self.modelUrl = Settings.modelUrl
		// Send notification
		NotificationCenter.default.post(
			name: Notifications.didSelectModel.name,
			object: nil
		)
	}
	
}
