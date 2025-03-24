//
//  ResourceSelectionView.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import Foundation
import SwiftUI

struct ResourceSelectionView: View {
	
	@Binding var expert: Expert
	@EnvironmentObject private var lengthyTasksController: LengthyTasksController
	
	var hasResources: Bool {
		return !expert.resources.resources.isEmpty
	}
	
	var isUpdating: Bool {
		let taskName: String = String(
			localized: "Updating resource index for expert \"\(self.expert.name)\""
		)
		return lengthyTasksController.tasks
			.map(\.name)
			.contains(
				taskName
			)
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
			$expert.resources.resources,
			editActions: .move
		) { resource in
			ResourceRowView(
				expert: $expert,
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
			Text(!isUpdating ? String(localized: "No resources") : String(localized: "Indexing in Progress"))
				.foregroundStyle(.secondary)
			if isUpdating {
				ProgressView()
					.progressViewStyle(.circular)
					.scaleEffect(0.5)
			}
			Spacer()
		}
	}
	
}

struct ResourceRowView: View {
	
	@Binding var expert: Expert
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
		Button {
			Task { @MainActor in
				await remove()
			}
		} label: {
			Label("Remove", systemImage: "trash")
				.foregroundStyle(.red)
				.labelStyle(.iconOnly)
		}
		.buttonStyle(.plain)
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
		await $expert.removeResource(resource)
	}
	
}

//#Preview {
//    ResourceSelectionView()
//}
