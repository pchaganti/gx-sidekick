//
//  LengthyTasksToolbarButton.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI

struct LengthyTasksToolbarButton: View {
	
    var body: some View {
		PopoverButton(arrowEdge: .bottom) {
			Label("Tasks", systemImage: "arrow.trianglehead.2.clockwise")
		} content: {
			LengthyTasksList()
		}
    }
	
}

#Preview {
    LengthyTasksToolbarButton()
}
