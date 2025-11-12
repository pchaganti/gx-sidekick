//
//  UserMessageAttachmentView.swift
//  Sidekick
//
//  Created by Bean John on 11/11/25.
//

import SwiftUI

struct UserMessageAttachmentView: View {
    
    var referencedURL: ReferencedURL
    
    var body: some View {
        Button {
            referencedURL.open()
        } label: {
            HStack(spacing: 10) {
                thumbnail
                Text(referencedURL.displayName)
                    .bold()
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 220, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .frame(maxWidth: 260, alignment: .leading)
            .padding(4)
        }
        .buttonStyle(CapsuleButtonStyle())
        .contextMenu {
            if !referencedURL.url.isWebURL {
                Button {
                    FileManager.showItemInFinder(
                        url: referencedURL.url
                    )
                } label: {
                    Text("Show in Finder")
                }
            }
        }
    }
    
    @ViewBuilder
    private var thumbnail: some View {
        if referencedURL.url.isFileURL {
            ThumbnailView(
                url: referencedURL.url,
                resolution: CGSize(
                    width: 96,
                    height: 96
                ),
                scale: 1,
                representationTypes: .thumbnail,
                tapToPreview: true,
                resizable: true
            )
            .aspectRatio(contentMode: .fill)
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
        }
    }
    
}
