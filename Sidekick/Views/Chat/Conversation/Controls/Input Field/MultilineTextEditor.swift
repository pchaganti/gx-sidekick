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
        if textView.string != text {
            DispatchQueue.main.async {
                withAnimation(.linear) {
                    textView.string = text
                }
            }
        }
        textView.setPrompt(prompt)
        if textView.selectedRange.location != insertionPoint {
            DispatchQueue.main.async {
                textView.setSelectedRange(NSRange(location: insertionPoint, length: 0))
            }
        }
        // Invalidate intrinsic content size for height recalculation
        textView.invalidateIntrinsicContentSize()
        nsView.invalidateIntrinsicContentSize()
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MultilineTextField
        
        init(_ parent: MultilineTextField) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            withAnimation(.linear) {
                parent.text = textView.string
            }
            parent.insertionPoint = textView.selectedRange.location
            textView.invalidateIntrinsicContentSize()
            textView.enclosingScrollView?.invalidateIntrinsicContentSize()
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.insertionPoint = textView.selectedRange.location
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
                .foregroundColor: NSColor.placeholderTextColor,
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
    
}
