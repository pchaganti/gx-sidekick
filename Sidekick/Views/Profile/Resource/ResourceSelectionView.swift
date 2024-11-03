//
//  ResourceSelectionView.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import Foundation
import SwiftUI

struct ResourceSelectionView: View {
	
	@Binding var profile: Profile
	
	var hasResources: Bool {
		return !profile.resources.resources.isEmpty
	}
	
	var body: some View {
		Group {
			if hasResources {
				list
			} else {
				noResources
			}
		}
		.frame(minHeight: 30)
		.padding(3)
	}
	
	var list: some View {
		List(
			$profile.resources.resources,
			editActions: .move
		) { resource in
			ResourceRowView(
				profile: $profile,
				resource: resource
			)
			.transition(
				.asymmetric(
					insertion: .push(from: .leading),
					removal: .move(edge: .leading)
				)
			)
		}
		.padding(.horizontal)
		.listStyle(.plain)
	}
	
	var noResources: some View {
		HStack {
			Spacer()
			Text("No resources")
				.foregroundStyle(.secondary)
			Spacer()
		}
	}
	
}

struct ResourceRowView: View {
	
	@Binding var profile: Profile
	@Binding var resource: Resource
	
	@State private var isHovering: Bool = false

	var body: some View {
		HStack {
			Text(resource.name)
			Spacer()
		}
		.overlay(alignment: .trailing) {
			if isHovering {
				actions
			}
		}
		.onHover { hover in
			withAnimation(.linear) {
				isHovering = hover
			}
		}
		.contextMenu {
			if !resource.url.isWebURL && isHovering {
				showInFinder
			}
		}
	}
	
	var actions: some View {
		HStack {
			Button {
				let result: Bool = NSWorkspace.shared.open(
					resource.url
				)
				if !result {
					let _ = Dialogs.showAlert(
						title: String(localized: "Error"),
						message: String(localized: "Failed to open \(resource.filename)")
					)
				}
			} label: {
				Label("Open", systemImage: "pip.exit")
					.foregroundStyle(.primary)
					.labelStyle(.iconOnly)
			}
			.buttonStyle(PlainButtonStyle())
			Button {
				Task.detached { @MainActor in
					await remove()
				}
			} label: {
				Label("Remove", systemImage: "trash")
					.foregroundStyle(.red)
					.labelStyle(.iconOnly)
			}
			.buttonStyle(PlainButtonStyle())
		}
	}
	
	var showInFinder: some View {
		Button {
			FileManager.showItemInFinder(
				url: resource.url
			)
		} label: {
			Text("Show in Finder")
		}
		.keyboardShortcut("f", modifiers: .command)
	}
	
	@MainActor
	func remove() async {
		await $profile.removeResource(resource)
	}
	
}

//#Preview {
//    ResourceSelectionView()
//}
