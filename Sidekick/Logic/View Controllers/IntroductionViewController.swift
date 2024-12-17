//
//  IntroductionViewController.swift
//  Sidekick
//
//  Created by Bean John on 12/15/24.
//

import Foundation
import SwiftUI

public class IntroductionViewController: ObservableObject {
	
	@Published var page: IntroductionPage = IntroductionPage.allCases.first!
	
	public var progress: some View {
		HStack {
			ForEach(IntroductionPage.allCases.indices) { index in
				Circle()
					.frame(width: 7.5)
					.foregroundColor({
						if index == self.page.progress {
							return Color.primary
						}
						return Color.secondary
					}())
			}
		}
	}
	
	public var prevPage: some View {
		Button {
			self.page.prevPage()
		} label: {
			Image(
				systemName: "chevron.left"
			)
			.imageScale(.large)
		}
		.buttonStyle(.plain)
		.keyboardShortcut(.leftArrow)
		.disabled(!page.hasPrevPage)
	}
	
	public var nextPage: some View {
		Button {
			self.page.nextPage()
		} label: {
			Image(
				systemName: "chevron.right"
			)
			.imageScale(.large)
		}
		.buttonStyle(.plain)
		.keyboardShortcut(.rightArrow)
		.disabled(!page.hasNextPage)
	}
	
}
