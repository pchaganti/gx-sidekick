//
//  ProfileNavigationRowView.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import SwiftUI

struct ProfileNavigationRowView: View {
	
	@EnvironmentObject private var profileManager: ProfileManager
	
	@State private var isEditing: Bool = false
	@State private var isHovering: Bool = false
	
	@Binding var profile: Profile
	
	var isDefault: Bool {
		return profile.id == profileManager.default?.id
	}
	
	var body: some View {
		HStack {
			Button {
				self.isEditing.toggle()
			} label: {
				self.profile.label
			}
			.buttonStyle(.plain)
			Spacer()
			if isHovering && !isDefault {
				Group {
					deleteButton
					Image(systemName: "line.3.horizontal")
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding(.leading, 4)
		.padding(.trailing)
		.background {
			RoundedRectangle(cornerRadius: 7)
				.fill(self.profile.color)
		}
		.sheet(isPresented: $isEditing) {
			ProfileEditorView(
				profile: $profile, isEditing: $isEditing
			)
			.frame(minWidth: 500, maxHeight: 800)
		}
		.contextMenu {
			deleteButton
		}
		.onHover { hover in
			isHovering = hover
		}
	}
	
	var deleteButton: some View {
		Button {
			self.delete(profile.id)
		} label: {
			Label("Delete", systemImage: "trash")
				.foregroundStyle(.red)
				.labelStyle(.iconOnly)
				.bold()
		}
		.buttonStyle(.plain)
	}
	
	private func delete(_ profileId: UUID) {
		let _ = Dialogs.showConfirmation(
			title: String(localized: "Delete Profile"),
			message: String(localized: "Are you sure you want to delete this Profile?")
		) {
			if let profile = profileManager.getProfile(
				id: profileId
			) {
				self.profileManager.delete(profile)
			}
		}
	}
	
}
