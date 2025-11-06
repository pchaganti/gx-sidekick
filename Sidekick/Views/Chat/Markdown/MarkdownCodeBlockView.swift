//
//  MarkdownCodeBlockView.swift
//  Sidekick
//
//  Created by Bean John on 11/7/24.
//

import MarkdownUI
import SwiftUI

struct MarkdownCodeBlockView: View {
    
    var configuration: CodeBlockConfiguration
    
    @State private var isExpanded: Bool?
    
    private let collapsedLineCount: Int = 10
    
    private var effectiveIsExpanded: Bool {
        // If isExpanded is nil (first load), determine based on line count
        // Short code (10 lines or less) starts expanded
        return isExpanded ?? (totalLineCount <= collapsedLineCount)
    }
    
    var languageName: String? {
        guard let langName: String = configuration.language?.capitalized else {
            return nil
        }
        if langName.isEmpty {
            return nil
        }
        return langName
    }
    
    var totalLineCount: Int {
        return configuration.content.components(separatedBy: .newlines).count
    }
    
    var shouldShowExpandButton: Bool {
        return totalLineCount > collapsedLineCount
    }
    
    var displayedContent: String {
        if effectiveIsExpanded || !shouldShowExpandButton {
            return configuration.content
        }
        let lines = configuration.content.components(separatedBy: .newlines)
        return lines.prefix(collapsedLineCount).joined(separator: "\n")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with buttons
            HStack(spacing: 8) {
                if let languageName {
                    Text(languageName)
                        .bold()
                }
                Spacer()
                if shouldShowExpandButton {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded = !(isExpanded ?? (totalLineCount <= collapsedLineCount))
                        }
                    } label: {
                        Image(systemName: effectiveIsExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .imageScale(.medium)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                }
                ExportButton(
                    text: configuration.content,
                    language: configuration.language
                )
                CopyButton(text: configuration.content)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            // Code content
            ZStack(alignment: .bottom) {
                Group {
                    if effectiveIsExpanded {
                        // Expanded: Show with syntax highlighting
                        ScrollView(.horizontal) {
                            configuration.label
                                .relativeLineSpacing(.em(0.225))
                                .markdownTextStyle {
                                    FontFamilyVariant(.monospaced)
                                    FontSize(.em(0.85))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                    } else {
                        // Collapsed: Show plain text without highlighting
                        ScrollView(.horizontal) {
                            Text(displayedContent)
                                .font(.system(size: NSFont.systemFontSize * 0.85, design: .monospaced))
                                .lineSpacing(NSFont.systemFontSize * 0.85 * 0.225)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                        .frame(height: CGFloat(collapsedLineCount) * (NSFont.systemFontSize * 0.85 * 1.225))
                        .clipped()
                    }
                }
                
                // Bottom overlay with "Show all N lines" button
                if !effectiveIsExpanded && shouldShowExpandButton {
                    ZStack(alignment: .bottom) {
                        // Gradient fade extending through entire overlay
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.secondaryBackground.opacity(0), location: 0),
                                .init(color: Color.secondaryBackground.opacity(0.95), location: 0.5),
                                .init(color: Color.secondaryBackground, location: 1)
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
                                            .stroke(Color.border.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                    }
                    .frame(height: 70)
                }
            }
        }
        .background(Color.secondaryBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 6,
                style: .continuous
            )
        )
    }
    
}

extension Color {
    
    fileprivate static let text = Color(
        light: Color(rgba: 0x0606_06ff), dark: Color(rgba: 0xfbfb_fcff)
    )
    fileprivate static let secondaryText = Color(
        light: Color(rgba: 0x6b6e_7bff), dark: Color(rgba: 0x9294_a0ff)
    )
    fileprivate static let tertiaryText = Color(
        light: Color(rgba: 0x6b6e_7bff), dark: Color(rgba: 0x6d70_7dff)
    )
    fileprivate static let background = Color.clear
    fileprivate static let secondaryBackground = Color(
        light: Color(rgba: 0xf7f7_f9ff), dark: Color(rgba: 0x2526_2aff)
    )
    fileprivate static let link = Color(
        light: Color(rgba: 0x2c65_cfff), dark: Color(rgba: 0x4c8e_f8ff)
    )
    fileprivate static let border = Color(
        light: Color(rgba: 0xe4e4_e8ff), dark: Color(rgba: 0x4244_4eff)
    )
    fileprivate static let divider = Color(
        light: Color(rgba: 0xd0d0_d3ff), dark: Color(rgba: 0x3334_38ff)
    )
    fileprivate static let checkbox = Color(rgba: 0xb9b9_bbff)
    fileprivate static let checkboxBackground = Color(rgba: 0xeeee_efff)
    
}
