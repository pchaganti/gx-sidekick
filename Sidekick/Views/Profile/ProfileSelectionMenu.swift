//
//  ProfileSelectionMenu.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ProfileSelectionMenu: View {
	
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var inactiveProfiles: [Profile] {
		return profileManager.profiles.filter({ profile in
			profile != selectedProfile
		})
	}
	
    var body: some View {
		Group {
			prevButton
			menu
			nextButton
		}
    }
	
	var prevButton: some View {
		Button {
			withAnimation(.linear) {
				switchToPrevProfile()
			}
		} label: {
			Label("Previous Profile", systemImage: "chevron.backward")
		}
		.keyboardShortcut("[", modifiers: [.command])
	}
	
	var nextButton: some View {
		Button {
			withAnimation(.linear) {
				switchToNextProfile()
			}
		} label: {
			Label("Next Profile", systemImage: "chevron.forward")
		}
		.keyboardShortcut("]", modifiers: [.command])
	}
	
	var menu: some View {
		Menu {
			Group {
				selectOptions
				if !inactiveProfiles.isEmpty {
					Divider()
				}
				manageProfilesButton
			}
		} label: {
			label
		}
	}
	
	var selectOptions: some View {
		ForEach(
			inactiveProfiles
		) { profile in
			Button {
				withAnimation(.linear) {
					conversationState.selectedProfileId = profile.id
				}
			} label: {
				profile.label
			}
		}
	}
	
	var manageProfilesButton: some View {
		Button {
			conversationState.isManagingProfiles.toggle()
		} label: {
			Text("Manage Profiles")
		}
	}
	
	var label: some View {
		Group {
			if selectedProfile == nil {
				Text("Select a Profile")
					.bold()
					.padding(7)
					.padding(.horizontal, 2)
					.foregroundStyle(Color.black)
					.background {
						RoundedRectangle(cornerRadius: 8)
							.fill(Color.white)
							.opacity(0.5)
					}
			} else {
				selectedProfile?.label
			}
		}
	}
	
	/// Function to switch to the next profile
	private func switchToNextProfile() {
		let profilesIds: [UUID] = (profileManager.profiles + profileManager.profiles).map({ $0.id })
		guard let selectedProfileId = conversationState.selectedProfileId else {
			conversationState.selectedProfileId = profileManager.firstProfile?.id
			return
		}
		guard let index = profilesIds.firstIndex(of: selectedProfileId) else { return }
		self.conversationState.selectedProfileId = profilesIds[index + 1]
	}
	
	/// Function to switch to the last profile
	private func switchToPrevProfile() {
		let profilesIds: [UUID] = (profileManager.profiles + profileManager.profiles).map({ $0.id })
		guard let selectedProfileId = conversationState.selectedProfileId else {
			conversationState.selectedProfileId = profileManager.lastProfile?.id
			return
		}
		guard let index = profilesIds.lastIndex(of: selectedProfileId) else { return }
		self.conversationState.selectedProfileId = profilesIds[index - 1]
	}
	
}

//#Preview {
//    ProfileSelectionMenu()
//}
