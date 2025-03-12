//
//  ServerModelSetupView.swift
//  Sidekick
//
//  Created by John Bean on 3/12/25.
//

import SwiftUI

struct ServerModelSetupView: View {
	
	@Binding var isPresented: Bool
	@Binding var selectedModel: Bool
	
	@AppStorage("remoteModelName") private var serverModelName: String = ""
	@AppStorage("endpoint") private var endpoint: String = ""
	@AppStorage("useServer") private var useServer: Bool = true
	
	var canContinue: Bool {
		// Allow continue if any of local or server model is setup
		let serverIsSetup: Bool = !serverModelName.isEmpty && !endpoint.isEmpty && useServer
		let localIsSetup: Bool = Settings.modelUrl?.fileExists ?? false
		return serverIsSetup || localIsSetup
	}
	
    var body: some View {
		VStack {
			form
			Divider()
			HStack {
				Spacer()
				Group {
					cancelButton
					continueButton
				}
				.controlSize(.large)
			}
			.padding([.bottom, .trailing], 9)
			.padding(.vertical, 4)
		}
    }
	
	var form: some View {
		Form {
			ServerModelSettingsView()
		}
		.formStyle(.grouped)
		.scrollIndicators(.never)
	}
	
	var cancelButton: some View {
		Button {
			self.isPresented.toggle()
		} label: {
			Text("Cancel")
		}
	}
	
	var continueButton: some View {
		Button {
			// Hide sheet
			self.selectedModel = true
			self.isPresented = false
		} label: {
			Text("Continue")
		}
		.disabled(!canContinue)
		.keyboardShortcut(.defaultAction)
	}
	
}
