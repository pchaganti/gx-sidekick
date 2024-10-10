//
//  ProfileSelectionMenu.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ProfileSelectionMenu: View {
	
	@EnvironmentObject private var profileManager: ProfileManager
	@Binding var selectedProfileId: UUID?
	@Binding var isCreatingProfile: Bool
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = selectedProfileId else { return nil }
		return profileManager.getProfile(id: selectedProfileId)
	}
	
	var inactiveProfiles: [Profile] {
		return profileManager.profiles.filter({ profile in
			profile != selectedProfile
		})
	}
	
    var body: some View {
		Menu {
			Group {
				selectOptions
				if !inactiveProfiles.isEmpty {
					Divider()
				}
				newProfileButton
			}
		} label: {
			label
		}
    }
	
	var selectOptions: some View {
		ForEach(inactiveProfiles) { profile in
			Button {
				selectedProfileId = profile.id
			} label: {
				profile.label
			}
		}
	}
	
	var newProfileButton: some View {
		Button {
			isCreatingProfile.toggle()
		} label: {
			Label("New Profile", systemImage: "plus")
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
	
}

//#Preview {
//    ProfileSelectionMenu()
//}
