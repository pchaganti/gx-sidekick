//
//  TemporaryResourcesView.swift
//  Sidekick
//
//  Created by Bean John on 10/24/24.
//

import SwiftUI

struct TemporaryResourcesView: View {
	
	@Binding var tempResources: [TemporaryResource]
	
	var body: some View {
		VStack(
			alignment: .leading,
			spacing: 4
		) {
			label
			resourcesCarousel
		}
	}
	
	var label: some View {
		Text("Temporary Resources:")
			.bold()
			.font(.body)
			.foregroundStyle(Color.secondary)
			.padding(.horizontal, 7)
			.padding(.vertical, 5)
			.background {
				Capsule()
					.fill(Color.buttonBackground)
			}
			.padding(.leading, 13)
	}
	
	var resourcesCarousel: some View {
		ScrollView(
			.horizontal,
			showsIndicators: false
		) {
			HStack {
				ForEach(
					self.$tempResources
				) { tempResource in
					TemporaryResourceView(
						tempResources: $tempResources,
						tempResource: tempResource
					)
					.transition(
						.scale
					)
				}
				Spacer()
			}
			.padding(.horizontal, 10)
		}
		.mask {
			Rectangle()
				.overlay(alignment: .leading) {
					ScrollMask(isLeading: true)
				}
				.overlay(alignment: .trailing) {
					ScrollMask(isLeading: false)
				}
		}
		.padding(.horizontal, 10)
	}
	
}

//#Preview {
//    TemporaryResourcesView()
//}
