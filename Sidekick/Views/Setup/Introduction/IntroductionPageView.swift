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
                .frame(height: 400)
            Text(content.title)
                .font(.title)
                .bold()
                .padding(.vertical, 10)
            Markdown(MarkdownContent(content.description))
                .font(.title2)
        }
        .frame(minWidth: 700, minHeight: 550)
    }
	
}
