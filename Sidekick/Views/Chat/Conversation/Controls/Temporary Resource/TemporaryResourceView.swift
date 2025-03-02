//
//  TemporaryResourceView.swift
//  Sidekick
//
//  Created by Bean John on 10/24/24.
//

import SwiftUI

struct TemporaryResourceView: View {
	
	@Binding var tempResources: [TemporaryResource]
	@Binding var tempResource: TemporaryResource
	@State private var isHovering: Bool = false
	
	var buttonOpacity: CGFloat {
		return isHovering ? 1 : 0
	}
	
    var body: some View {
		Button {
			self.open()
		} label: {
			self.label
				.frame(
					maxWidth: 275,
					maxHeight: 60
				)
		}
		.buttonStyle(CapsuleButtonStyle())
		.overlay(alignment: .topTrailing) {
			removeButton
				.opacity(buttonOpacity)
		}
		.onHover { hovering in
			self.isHovering = hovering
		}
		.onAppear {
			Task.detached { @MainActor in
				await $tempResource.scan()
			}
		}
		.contextMenu {
			showInFinder
		}
    }
	
	var removeButton: some View {
		Button {
			withAnimation(
				.linear
			) {
				self.tempResources = self.tempResources.filter {
					$0.id != self.tempResource.id
				}
			}
		} label: {
			Image(systemName: "xmark.circle.fill")
				.foregroundStyle(.red)
				.background {
					Circle()
						.fill(.white)
						.padding(3)
				}
		}
		.buttonStyle(.plain)
	}
	
	var showInFinder: some View {
		Button {
			FileManager.showItemInFinder(
				url: tempResource.url
			)
		} label: {
			Text("Show in Finder")
		}
	}
	
	var label: some View {
		HStack(spacing: 10) {
			QLThumbnail(
				url: tempResource.url,
				resolution: CGSize(
					width: 128,
					height: 128
				),
				scale: 1,
				representationTypes: .thumbnail,
				tapToPreview: true,
				resizable: false
			)
			Text(tempResource.name)
				.bold()
				.foregroundStyle(.secondary)
				.frame(maxWidth: 225)
				.lineLimit(nil)
				.padding(.vertical, 5)
		}
		.padding(.trailing, 5)
		.if(self.tempResource.state == .notScanned) { view in
			view
				.brightness(-0.5)
				.blur(radius: 10)
				.overlay(loadingOverlay)
		}
		.if(self.tempResource.state == .failed) { view in
			view
				.brightness(-0.5)
				.blur(radius: 10)
				.overlay {
					Text("Failed to extract text")
				}
		}
	}
	
	var loadingOverlay: some View {
		HStack {
			ProgressView()
				.progressViewStyle(.circular)
			Text("Extracting text...")
		}
	}
	
	private func open() {
		NSWorkspace.shared.open(tempResource.url)
	}
	
}
