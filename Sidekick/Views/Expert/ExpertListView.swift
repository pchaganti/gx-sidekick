//
//  ExpertListView.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ExpertListView: View {
	
	@EnvironmentObject private var expertManager: ExpertManager
	
    var body: some View {
		List(
			self.$expertManager.experts,
			editActions: .move
		) { expert in
			ExpertNavigationRowView(
				expert: expert
			)
			.listRowSeparator(.hidden)
		}
    }
	
}
