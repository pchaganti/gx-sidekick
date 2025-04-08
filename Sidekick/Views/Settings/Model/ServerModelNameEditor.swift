//
//  ServerModelNameEditor.swift
//  Sidekick
//
//  Created by John Bean on 3/12/25.
//

import SwiftUI

struct ServerModelNameEditor: View {
	
	@Binding var serverModelName: String
    
	var modelType: ModelType
	
	/// A localized `String` containing the title shown for the editor
	var editorTitle: String {
		switch self.modelType {
            case .worker:
                return String(localized: "Remote Worker Model Name")
            default:
                return String(localized: "Remote Model Name")
		}
	}
	
	/// A localized `String` containing the description shown for the editor
	var editorDescription: String {
		switch self.modelType {
            case .worker:
                return String(localized: "The worker model's name. (e.g. gpt-4o-mini) The worker model is used for simpler tasks like generating chat titles.\n\nLeave this blank to use the main model for all tasks.")
            default:
                return String(localized: "The model's name. (e.g. gpt-4o)")
		}
	}
	
	var body: some View {
        HStack(alignment: .center) {
            description
            Spacer()
            ModelNameMenu(
                modelTypes: [.remote],
                serverModelName: self.$serverModelName
            )
            .frame(maxWidth: 150)
        }
	}
	
	var description: some View {
		VStack(alignment: .leading) {
			Text(self.editorTitle)
				.font(.title3)
				.bold()
			Text(self.editorDescription)
				.font(.caption)
		}
	}
	
}
