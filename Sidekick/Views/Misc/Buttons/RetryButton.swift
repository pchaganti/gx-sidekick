//
//  RegenerateButton.swift
//  Sidekick
//
//  Created by John Bean on 3/7/25.
//

import SwiftUI

struct RegenerateButton: View {
	
	var action: () -> Void = {}
	
    var body: some View {
		Button {
			self.action()
		} label: {
			Label(
				"Retry",
				systemImage: "arrow.trianglehead.clockwise"
			)
		}
		.buttonStyle(.plain)
    }
	
}
