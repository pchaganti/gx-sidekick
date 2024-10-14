//
//  ProfileManagerView.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ProfileManagerView: View {
	
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	@State private var selectedProfileId: UUID? = ProfileManager.shared.firstProfile?.id
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = selectedProfileId else { return nil }
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	@State private var editingProfile: Profile = ProfileManager.shared.firstProfile!
	
	var body: some View {
		VStack {
			HStack {
				ExitButton {
					conversationState.isManagingProfiles.toggle()
				}
				Spacer()
			}
			.padding(.leading)
			ProfileListView()
			Spacer()
			newProfileButton
		}
		.padding(.vertical)
	}
	
	var newProfileButton: some View {
		Button {
			newProfile()
		} label: {
			Label("Add Profile", systemImage: "plus")
		}
		.buttonStyle(PlainButtonStyle())
	}
	
	private func newProfile() {
		let newProfile: Profile = Profile(
			name: "Untitled",
			symbolName: "questionmark.circle.fill",
			color: Color.white
		)
		profileManager.add(newProfile)
	}
	
}

//#Preview {
//    ProfileManagerView()
//}
