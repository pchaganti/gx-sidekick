//
//  CollapsibleUserMessageView.swift
//  Sidekick
//
//  Created by John Bean on 11/5/25.
//

import SwiftUI

struct CollapsibleUserMessageView: View {
    
    var text: String
    
    @State private var isExpanded: Bool?
    
    private let collapsedLineCount: Int = 15
    
    private var effectiveIsExpanded: Bool {
        // If isExpanded is nil (first load), determine based on line count
        // Short messages (15 lines or less) start expanded
        return isExpanded ?? (totalLineCount <= collapsedLineCount)
    }
    
    var totalLineCount: Int {
        return text.components(separatedBy: .newlines).count
    }
    
    var shouldShowExpandButton: Bool {
        return totalLineCount > collapsedLineCount
    }
    
    var displayedContent: String {
        if effectiveIsExpanded || !shouldShowExpandButton {
            return text
        }
        let lines = text.components(separatedBy: .newlines)
        return lines.prefix(collapsedLineCount).joined(separator: "\n")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                // Message text
                Text(displayedContent)
                    .font(.system(size: NSFont.systemFontSize + 1.0))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .if(!effectiveIsExpanded && shouldShowExpandButton) { view in
                        view.frame(maxHeight: calculateCollapsedHeight())
                    }
                
                // Bottom overlay with "Show all N lines" button
                if !effectiveIsExpanded && shouldShowExpandButton {
                    ZStack(alignment: .bottom) {
                        // Gradient fade extending through entire overlay
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(nsColor: .textBackgroundColor).opacity(0), location: 0),
                                .init(color: Color(nsColor: .textBackgroundColor).opacity(0.95), location: 0.5),
                                .init(color: Color(nsColor: .textBackgroundColor), location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Button centered at bottom
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Show all \(totalLineCount) lines")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                    }
                    .frame(height: 70)
                }
            }
            
            // Collapse button at bottom when expanded
            if effectiveIsExpanded && shouldShowExpandButton {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 11, weight: .medium))
                            Text("Show less")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    Spacer()
                }
            }
        }
        .textSelection(.enabled)
    }
    
    private func calculateCollapsedHeight() -> CGFloat {
        let fontSize = NSFont.systemFontSize + 1.0
        let lineSpacing: CGFloat = 4
        let lineHeight = fontSize + lineSpacing
        return CGFloat(collapsedLineCount) * lineHeight
    }
}

