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
	
	var body: some View {
		HStack {
			profile.label
			Spacer()
			if isHovering {
				buttons
			}
		}
		.padding(.horizontal)
		.background {
			RoundedRectangle(cornerRadius: 8)
				.fill(profile.color)
		}
		.onTapGesture {
			isEditing.toggle()
		}
		.sheet(isPresented: $isEditing) {
			ProfileEditorView(
				profile: $profile, isEditing: $isEditing
			)
			.frame(minWidth: 500, maxHeight: 800)
		}
		.contextMenu {
			buttons
		}
		.onHover { hover in
			isHovering = hover
		}
	}
	
	var buttons: some View {
		Group {
			Button {
				self.delete(profile.id)
			} label: {
				Label("Delete", systemImage: "trash")
					.foregroundStyle(.red)
			}
		}
		.labelStyle(.iconOnly)
	}
	
	private func delete(_ profileId: UUID) {
		let _ = Dialogs.showConfirmation(
			title: "Delete Profile",
			message: "Are you sure you want to delete this Profile?"
		) {
			if let profile = profileManager.getProfile(
				id: profileId
			) {
				profileManager.delete(profile)
			}
		}
	}
	
}

//#Preview {
//    ProfileNavigationRowView()
//}
