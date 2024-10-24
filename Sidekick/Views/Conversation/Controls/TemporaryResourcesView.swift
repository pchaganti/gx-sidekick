//
//  TemporaryResourcesView.swift
//  Sidekick
//
//  Created by Bean John on 10/24/24.
//

import SwiftUI

struct TemporaryResourcesView: View {
	
	@EnvironmentObject private var promptController: PromptController
	
    var body: some View {
		ScrollView(
			.horizontal,
			showsIndicators: false
		) {
			HStack {
				ForEach(
					self.$promptController.tempResources
				) { tempResource in
					TemporaryResourceView(
						tempResource: tempResource
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
