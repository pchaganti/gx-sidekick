//
//  ProfileListView.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ProfileListView: View {
	
	@EnvironmentObject private var profileManager: ProfileManager
	
    var body: some View {
		List(
			self.$profileManager.profiles,
			editActions: .move
		) { profile in
			ProfileNavigationRowView(profile: profile)
				.listRowSeparator(.hidden)
		}
    }
	
}

//#Preview {
//	ProfileListView()
//}
