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
