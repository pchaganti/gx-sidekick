//
//  MultilineTextEditor.swift
//  Sidekick
//
//  Created by John Bean on 4/20/25.
//

import SwiftUI
import AppKit

struct MultilineTextField: NSViewRepresentable {
    
    @Binding var text: String
    @Binding var insertionPoint: Int
    let prompt: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> PromptingScrollView {
        let scrollView = PromptingScrollView()
        let textView = PromptingTextView()
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.delegate = context.coordinator
        textView.setPrompt(prompt)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 2, height: 4)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.setContentHuggingPriority(.required, for: .vertical)
        scrollView.setContentCompressionResistancePriority(.required, for: .vertical)
        return scrollView
    }
    
    func updateNSView(_ nsView: PromptingScrollView, context: Context) {
        guard let textView = nsView.documentView as? PromptingTextView else { return }
        // Only update if the text changed externally (not while user is editing)
        if textView.window?.firstResponder != textView {
            if textView.string != text {
                textView.string = text
            }
            if textView.selectedRange.location != insertionPoint {
                textView.setSelectedRange(NSRange(location: insertionPoint, length: 0))
            }
        }
        textView.setPrompt(prompt)
        // Invalidate intrinsic content size for height recalculation
        textView.invalidateIntrinsicContentSize()
        nsView.invalidateIntrinsicContentSize()
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        
        var parent: MultilineTextField
        private var previousTextWasEmpty: Bool = true
        
        init(_ parent: MultilineTextField) {
            self.parent = parent
        }
        
        func textDidChange(
            _ notification: Notification
        ) {
            guard let textView = notification.object as? NSTextView else { return }
            // Don't update during IME composition.
            if textView.hasMarkedText() { return }
            let newString = textView.string
            let cursor = textView.selectedRange.location
            // Animate when transitioning between empty and non-empty
            let nowEmpty = newString.isEmpty
            if previousTextWasEmpty != nowEmpty {
                withAnimation(.linear) {
                    parent.text = newString
                    parent.insertionPoint = cursor
                }
            } else {
                parent.text = newString
                parent.insertionPoint = cursor
            }
            previousTextWasEmpty = nowEmpty
            
            textView.invalidateIntrinsicContentSize()
            textView.enclosingScrollView?.invalidateIntrinsicContentSize()
        }
        
        func textViewDidChangeSelection(
            _ notification: Notification
        ) {
            guard let textView = notification.object as? NSTextView else { return }
            let cursor = textView.selectedRange.location
            if parent.insertionPoint != cursor {
                parent.insertionPoint = cursor
            }
        }
        
    }
    
}

class PromptingScrollView: NSScrollView {
    
    override var intrinsicContentSize: NSSize {
        if let docView = self.documentView {
            var size = docView.intrinsicContentSize
            size.width = NSView.noIntrinsicMetric
            return size
        }
        return super.intrinsicContentSize
    }
    
}

class PromptingTextView: NSTextView {
    
    private var prompt: String = ""
    
    override var intrinsicContentSize: NSSize {
        // Get font info
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer else {
            return super.intrinsicContentSize
        }
        layoutManager.ensureLayout(
            for: textContainer
        )
        let usedRect = layoutManager.usedRect(
            for: textContainer
        )
        let font = NSFont.systemFont(
            ofSize: NSFont.systemFontSize
        )
        let lineHeight = font.ascender - font.descender + font.leading
        // Calculate dimentions
        let minHeight = lineHeight + self.textContainerInset.height * 2
        let neededHeight = max(minHeight, usedRect.height + self.textContainerInset.height * 2)
        let width = self.enclosingScrollView?.frame.width ?? usedRect.width
        return NSSize(
            width: width,
            height: neededHeight
        )
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if string.isEmpty, !prompt.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
            let rect = bounds.insetBy(dx: 5, dy: 4)
            (prompt as NSString).draw(in: rect, withAttributes: attrs)
        }
    }
    
    func setPrompt(_ prompt: String) {
        DispatchQueue.main.async {
            withAnimation(.linear) {
                self.prompt = prompt
            }
        }
        needsDisplay = true
    }
    
    /// Function to force pasting as plain text
    override func paste(_ sender: Any?) {
        if let plainText = NSPasteboard.general.string(
            forType: .string
        ) {
            self.insertText(
                plainText,
                replacementRange: self.selectedRange()
            )
        } else {
            super.paste(sender)
        }
    }
    
}
