//
//  StopGenerationButton.swift
//  Sidekick
//
//  Created by Bean John on 10/17/24.
//

import SwiftUI
import SwiftUIX

struct StopGenerationButton: View {
	
	var action: () -> Void
	
    var body: some View {
		Button {
			self.action()
		} label: {
			Image(systemName: "stop.circle.fill")
				.foregroundStyle(.secondary)
		}
		.buttonStyle(.plain)
    }
	
}
