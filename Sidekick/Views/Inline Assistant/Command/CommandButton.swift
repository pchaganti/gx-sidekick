//
//  CommandButton.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import SwiftUI

struct CommandButton: View {
	
	init(
		command: Command,
		action: @escaping () -> Void
	) {
		self.command = command
		self.action = action
	}
	
	@EnvironmentObject private var model: Model
	@EnvironmentObject private var commandManager: CommandManager
	@EnvironmentObject private var inlineAssistantController: InlineAssistantController
	
	var command: Command
	var action: () -> Void
	
    var body: some View {
		Button {
			self.action()
		} label: {
			label
		}
		.buttonStyle(.plain)
		.contextMenu {
			Button {
				self.commandManager.delete(self.command)
			} label: {
				Text("Delete")
			}
		}
    }
	
	var label: some View {
		Text(self.command.name)
			.bold()
			.padding(5)
			.background {
				RoundedRectangle(
					cornerRadius: 5
				)
				.fill(Color.textBackground)
			}
			.font(.body)
	}
	
}
