//
//  MessageContentView.swift
//  Sidekick
//
//  Created by Bean John on 11/12/24.
//

import LaTeXSwiftUI
import MarkdownUI
import Splash
import SwiftUI

struct MessageContentView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Asynchronously rendered markdown cached view.
    @State private var cachedMarkdown: AnyView? = nil
    // Stores the processed text after LaTeX conversion.
    @State private var processedText: String = ""
    // Used to debounce rapid changes.
    @State private var debounceWorkItem: DispatchWorkItem?
    
    var text: String
    private let imageScaleFactor: CGFloat = 1.0
    
    // Computes the code highlighting theme from the color scheme.
    private var theme: Splash.Theme {
        switch colorScheme {
            case .dark:
                return .wwdc17(withFont: .init(size: 16))
            default:
                return .sunset(withFont: .init(size: 16))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Always render the inline markdown immediately using processedText
            // This provides quick visual feedback while the cached version is updated
            if let cached = cachedMarkdown {
                cached
            } else {
                markdownView(processedText.isEmpty ? text.convertLaTeX() : processedText)
            }
        }
        .onAppear {
            // Immediately update processed text and asynchronously update the cached markdown
            updateProcessedTextAndMarkdown(text)
        }
        .onChange(of: self.text) { _, newText in
            updateProcessedTextAndMarkdown(newText)
        }
    }
    
    /// Function to render a markdown view for the provided text
    @ViewBuilder
    private func markdownView(_ text: String) -> some View {
        Markdown(MarkdownContent(text))
            .markdownTheme(.gitHub)
            .markdownCodeSyntaxHighlighter(.splash(theme: theme))
            .markdownImageProvider(MarkdownImageProvider(scaleFactor: imageScaleFactor))
            .markdownInlineImageProvider(MarkdownInlineImageProvider(scaleFactor: imageScaleFactor))
            .textSelection(.enabled)
    }
    
    /// Function to update the processed text and debounce the cached markdown update
    private func updateProcessedTextAndMarkdown(_ newText: String) {
        let converted = newText.convertLaTeX()
        // Update inline view immediately.
        processedText = converted
        
        // Cancel any pending update.
        debounceWorkItem?.cancel()
        
        // Shorten debounce time to reduce perceived delay (e.g., 0.1 second).
        let workItem = DispatchWorkItem { [converted] in
            updateCachedMarkdown(with: converted)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
    
    /// Function to asynchronously render and update the cached markdown view.
    private func updateCachedMarkdown(with text: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let rendered = AnyView(
                Markdown(MarkdownContent(text))
                    .markdownTheme(.gitHub)
                    .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
                    .markdownImageProvider(MarkdownImageProvider(scaleFactor: self.imageScaleFactor))
                    .markdownInlineImageProvider(MarkdownInlineImageProvider(scaleFactor: self.imageScaleFactor))
                    .textSelection(.enabled)
            )
            DispatchQueue.main.async {
                self.cachedMarkdown = rendered
            }
        }
    }
    
}
