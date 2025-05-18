//
//  WebsiteRowView.swift
//  Sidekick
//
//  Created by John Bean on 5/15/25.
//

import SwiftUI

struct WebsiteRowView: View {
    
    let url: URL
    
    @State private var title: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Favicon(url: url).getFavicon(size: .xl, width: 24)
                .frame(width: 24, height: 24)
                .cornerRadius(4)
            Link(
                self.title ?? self.url.absoluteString,
                destination: self.url
            )
            .lineLimit(1)
            .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .task {
            // Fetch title and domain only once
            if self.title == nil {
                await self.fetchMetadata()
            }
        }
    }
    
    /// Function to fetch the website's metadata
    private func fetchMetadata() async {
        // Fetch title
        let fetchedTitle = try? await url.fetchTitle()
        await MainActor.run {
            self.title = fetchedTitle ?? self.url.absoluteString
        }
    }
    
}
