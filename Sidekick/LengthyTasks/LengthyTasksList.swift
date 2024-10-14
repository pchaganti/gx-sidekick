//
//  LengthyTasksList.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI

struct LengthyTasksList: View {
	
	@EnvironmentObject private var lengthyTasksController: LengthyTasksController
	
    var body: some View {
		Group {
			if self.lengthyTasksController.tasks.isEmpty {
				noTasks
			} else {
				list
			}
		}
		.padding()
    }
	
	var noTasks: some View {
		Text("No tasks in progress")
	}
	
	var list: some View {
		VStack {
			Text("Ongoing Tasks")
				.font(.title3)
				.bold()
			Divider()
			ForEach(
				lengthyTasksController.tasks.indices,
				id: \.self
			) { index in
				HStack {
					Text(lengthyTasksController.tasks[index].name)
					Spacer()
					SpinnerView()
				}
				if index != (lengthyTasksController.tasks.count - 1) {
					Divider()
				}
			}
		}
	}
	
	private struct SpinnerView: View {
		
		var body: some View {
			ProgressView()
				.progressViewStyle(.circular)
				.scaleEffect(0.5, anchor: .center)
		}
		
	}
	
}

#Preview {
    LengthyTasksList()
}
