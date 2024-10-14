//
//  ResourceSelectionView.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import SwiftUI

struct ResourceSelectionView: View {
	
	@Binding var profile: Profile
	
	var body: some View {
		GroupBox {
			List(
				$profile.resources.resources,
				editActions: .move
			) { resource in
				ResourceRowView(
					profile: $profile,
					resource: resource
				)
			}
			.scrollDisabled(false)
			.frame(minHeight: 150, maxHeight: 200)
			.padding(3)
		}
		.padding(.vertical, 3)
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
	}
	
	var actions: some View {
		HStack {
			Button {
				let result: Bool = NSWorkspace.shared.open(
					resource.url
				)
				if !result {
					let _ = Dialogs.showAlert(
						title: "Error",
						message: "Failed to open \(resource.filename)"
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
	
	@MainActor
	func remove() async {
		await $profile.removeResource(resource)
	}
	
}

//#Preview {
//    ResourceSelectionView()
//}
