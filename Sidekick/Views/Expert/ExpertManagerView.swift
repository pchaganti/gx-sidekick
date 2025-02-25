//
//  ExpertManagerView.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ExpertManagerView: View {
	
	@EnvironmentObject private var expertManager: ExpertManager
	@EnvironmentObject private var conversationState: ConversationState
	
	@State private var selectedExpertId: UUID? = ExpertManager.shared.firstExpert?.id
	
	var selectedExpert: Expert? {
		guard let selectedExpertId = selectedExpertId else { return nil }
		return expertManager.getExpert(id: selectedExpertId)
	}
	
	@State private var editingExpert: Expert = ExpertManager.shared.firstExpert!
	
	var body: some View {
		VStack {
			HStack {
				ExitButton {
					conversationState.isManagingExperts.toggle()
				}
				Spacer()
			}
			.padding(.leading)
			ExpertListView()
			Spacer()
			newExpertButton
		}
		.padding(.vertical)
	}
	
	var newExpertButton: some View {
		Button {
			self.newExpert()
		} label: {
			Label("Add Expert", systemImage: "plus")
		}
		.buttonStyle(PlainButtonStyle())
	}
	
	private func newExpert() {
		let newExpert: Expert = Expert(
			name: "Untitled",
			symbolName: "questionmark.circle.fill",
			color: Color.white
		)
		self.expertManager.add(newExpert)
	}
	
}
