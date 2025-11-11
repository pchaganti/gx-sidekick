//
//  MarkdownTableView.swift
//  Sidekick
//
//  Created by Bean John on 11/6/24.
//

import MarkdownUI
import SwiftUI

struct MarkdownTableView: View, Equatable {
    
    var configuration: BlockConfiguration
    
    var body: some View {
        configuration.label
            .markdownTableBorderStyle(.init(color: .border))
            .markdownTableBackgroundStyle(
                .alternatingRows(Color.background, Color.secondaryBackground)
            )
    }
    
    // Equatable conformance for performance optimization
    static func == (lhs: MarkdownTableView, rhs: MarkdownTableView) -> Bool {
        // Compare based on the rendered markdown content
        return lhs.configuration.content.renderMarkdown() == rhs.configuration.content.renderMarkdown()
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
