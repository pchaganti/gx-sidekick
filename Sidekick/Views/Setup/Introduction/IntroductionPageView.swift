//
//  IntroductionPageView.swift
//  Sidekick
//
//  Created by Bean John on 12/17/24.
//

import MarkdownUI
import SwiftUI

struct IntroductionPageView: View {
	
	var content: IntroductionPage.Content
	
    var body: some View {
		VStack {
			content.image
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 800)
			Text(content.title)
				.font(.title)
				.bold()
				.padding(.bottom, 10)
			Markdown(content.description)
				.font(.title2)
		}
		.frame(maxHeight: 400)
    }
	
}
