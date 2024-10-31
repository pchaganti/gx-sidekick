//
//  SourcesView.swift
//  Sidekick
//
//  Created by Bean John on 10/20/24.
//

import SwiftUI

struct SourcesView: View {
	
	@Binding var isShowingSources: Bool
	var sources: Sources
	
	@State private var query: String = ""
	
	var filteredSources: [Source] {
		if query.isEmpty {
			return sources.sources.sorted(by: \.text)
		}
		let filteredSources: [Source] = sources.sources.filter { source in
			return source.text.lowercased().contains(query.lowercased())
		}
		return filteredSources.sorted(by: \.text)
	}
	
    var body: some View {
		VStack(
			alignment: .leading
		) {
			HStack {
				Text("Sources")
					.font(.title2)
					.bold()
				Spacer()
				TextField(text: $query, label: {
					Label("Search", systemImage: "magnifyingglass")
						.labelStyle(.titleAndIcon)
				})
				.textFieldStyle(.roundedBorder)
				.frame(maxWidth: 180)
				ExitButton {
					isShowingSources.toggle()
				}
			}
			.padding([.top, .trailing])
			Divider()
			List(
				filteredSources
			) { source in
				SourceRowView(source: source)
					.listRowSeparator(.hidden)
			}
		}
		.padding(.leading)
    }
}
