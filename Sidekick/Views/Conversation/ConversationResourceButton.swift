//
//  ConversationResourceButton.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import SwiftUI

struct ConversationResourceButton: View {
	
	@EnvironmentObject private var profileManager: ProfileManager
	@EnvironmentObject private var conversationState: ConversationState
	
	var selectedProfile: Profile? {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return nil
		}
		return profileManager.getProfile(id: selectedProfileId)
	}
	@Binding var profile: Profile
	
	@State private var isEditingResources: Bool = false
	
    var body: some View {
		Button {
			isEditingResources.toggle()
			self.updateProfile()
		} label: {
			Circle()
				.fill(profile.color.opacity(0.2))
				.frame(width: 32, height: 32)
				.overlay {
					profile.image
						.padding(10)
				}
		}
		.buttonStyle(ChatButtonStyle())
		.sheet(isPresented: $isEditingResources) {
			VStack(
				alignment: .leading,
				spacing: 0
			) {
				HStack {
					ExitButton {
						isEditingResources.toggle()
					}
					Spacer()
					Button {
						self.updateProfile()
					} label: {
						Image(systemName: "arrow.trianglehead.clockwise")
					}
					.buttonStyle(PlainButtonStyle())
				}
				.padding([.top, .horizontal])
				sheetContent
			}
		}
		.onChange(of: isEditingResources) {
			// Show tip if needed
			if !isEditingResources &&
				LengthyTasksController.shared.hasTasks {
				LengthyTasksProgressTip.hasLengthyTask = true
			}
		}
		.onChange(of: profile) {
			profileManager.update(profile)
		}
    }
	
	var sheetContent: some View {
		Form {
			ResourceSectionView(profile: $profile)
		}
		.formStyle(.grouped)
		.frame(maxWidth: 450, maxHeight: 600)
	}
	
	private func updateProfile() {
		guard let selectedProfileId = conversationState.selectedProfileId else {
			return
		}
		guard let profile = profileManager.getProfile(id: selectedProfileId) else { return }
		self.profile = profile
	}
	
}

//#Preview {
//    ConversationResourceButton()
//}
