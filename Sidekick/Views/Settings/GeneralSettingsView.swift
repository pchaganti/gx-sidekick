//
//  GeneralSettingsView.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI

struct GeneralSettingsView: View {
	
	@State private var playSoundEffects: Bool = Settings.playSoundEffects
	
    var body: some View {
		Form {
			Section {
				soundEffects
			} header: {
				Text("Sound Effects")
			}
		}
		.formStyle(.grouped)
    }
	
	var soundEffects: some View {
		HStack(alignment: .top) {
			VStack(alignment: .leading) {
				Text("Play Sound Effects")
					.font(.title3)
					.bold()
				Text("Play sound effects when text generation begins and ends.")
					.font(.caption)
			}
			Spacer()
			Toggle("", isOn: $playSoundEffects)
				.toggleStyle(.switch)
		}
		.onChange(of: playSoundEffects) {
			Settings.playSoundEffects = self.playSoundEffects
		}
	}
	
}

#Preview {
    GeneralSettingsView()
}
