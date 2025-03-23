//
//  ExpertSelectionMenu.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ExpertSelectionMenu: View {
	
	@Environment(\.colorScheme) var colorScheme
	
	@EnvironmentObject private var expertManager: ExpertManager
	@EnvironmentObject private var conversationState: ConversationState
	
	var selectedExpert: Expert? {
		guard let selectedExpertId = conversationState.selectedExpertId else {
			return nil
		}
		return expertManager.getExpert(id: selectedExpertId)
	}
	
	var isInverted: Bool {
		guard let luminance = selectedExpert?.color.luminance else { return false }
		let darkModeSetting: Bool = luminance > 0.5
		let lightModeSetting: Bool = luminance < 0.5
		return colorScheme == .dark ? darkModeSetting : lightModeSetting
	}
	
	var isDarkColor: Bool {
		guard let luminance = selectedExpert?.color.luminance else { return false }
		return luminance < 0.5
	}
	
	var inactiveExperts: [Expert] {
		return expertManager.experts.filter({ expert in
			expert != selectedExpert
		})
	}
	
	var createExpertsTip: CreateExpertsTip = .init()
	
	var body: some View {
		Group {
			prevButton
			menu
				.if(isInverted) { view in
					view.colorInvert()
				}
				.popoverTip(
					createExpertsTip,
					arrowEdge: .top
				) { action in
					// Open expert editor
					conversationState.isManagingExperts.toggle()
				}
			nextButton
		}
	}
	
	var prevButton: some View {
		Button {
			switchToPrevExpert()
		} label: {
			Label("Previous Expert", systemImage: "chevron.backward")
				.ifSequoia { view in
					view.foregroundStyle(
						isDarkColor ? .white.opacity(0.5) : .black.opacity(0.7)
					)
				}
		}
		.keyboardShortcut("[", modifiers: [.command])
	}
	
	var nextButton: some View {
		Button {
			switchToNextExpert()
		} label: {
			Label("Next Expert", systemImage: "chevron.forward")
				.ifSequoia { view in
					view.foregroundStyle(
						isDarkColor ? .white.opacity(0.5) : .black.opacity(0.7)
					)
				}
		}
		.keyboardShortcut("]", modifiers: [.command])
	}
	
	var menu: some View {
		Menu {
			Group {
				selectOptions
				if !inactiveExperts.isEmpty {
					Divider()
				}
				manageExpertsButton
			}
		} label: {
			label
		}
	}
	
	var selectOptions: some View {
		ForEach(
			inactiveExperts
		) { expert in
			Button {
				withAnimation(.linear) {
					conversationState.selectedExpertId = expert.id
				}
			} label: {
				expert.label
			}
		}
	}
	
	var manageExpertsButton: some View {
		Button {
			conversationState.isManagingExperts.toggle()
		} label: {
			Text("Manage Experts")
		}
		.onChange(of: conversationState.isManagingExperts) {
			// Show tip if needed
			if !conversationState.isManagingExperts &&
				LengthyTasksController.shared.hasTasks {
				LengthyTasksProgressTip.hasLengthyTask = true
			}
		}
	}
	
	var label: some View {
		Group {
			if selectedExpert == nil {
				Text("Select an Expert")
					.bold()
					.padding(7)
					.padding(.horizontal, 2)
					.background {
						RoundedRectangle(cornerRadius: 8)
							.fill(Color.white)
							.opacity(0.5)
					}
			} else {
				Label(
					self.selectedExpert!.name,
					systemImage: self.selectedExpert!.symbolName
				)
				.labelStyle(.titleAndIcon)
			}
		}
	}
	
	/// Function to switch to the next expert
	private func switchToNextExpert() {
		let expertsIds: [UUID] = (expertManager.experts + expertManager.experts).map({ $0.id })
		guard let selectedExpertId = conversationState.selectedExpertId else {
			withAnimation(.linear) {
				self.conversationState.selectedExpertId = expertManager.firstExpert?.id
			}
			return
		}
		guard let index = expertsIds.firstIndex(of: selectedExpertId) else {
			return
		}
		withAnimation(.linear) {
			self.conversationState.selectedExpertId = expertsIds[index + 1]
		}
	}
	
	/// Function to switch to the last expert
	private func switchToPrevExpert() {
		let expertsIds: [UUID] = (expertManager.experts + expertManager.experts).map({ $0.id })
		guard let selectedExpertId = conversationState.selectedExpertId else {
			withAnimation(.linear) {
				self.conversationState.selectedExpertId = expertManager.lastExpert?.id
			}
			return
		}
		guard let index = expertsIds.lastIndex(of: selectedExpertId) else {
			return
		}
		withAnimation(.linear) {
			self.conversationState.selectedExpertId = expertsIds[index - 1]
		}
	}
	
}
