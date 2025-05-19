//
//  DragModifier.swift
//  Sidekick
//
//  Created by John Bean on 5/19/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileDragProvider: NSViewRepresentable {
    var filePromise: FilePromise
    
    var preview: NSImage
    
    class NSViewType: NSView, NSFilePromiseProviderDelegate, NSDraggingSource {
        var filePromise: FilePromise
        var preview: NSImage
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError()
        }
        
        init(filePromise: FilePromise, preview: NSImage) {
            self.filePromise = filePromise
            self.preview = preview
            super.init(frame: .zero)
        }
        
        var mouseDownLocation: CGPoint = .zero
        override func mouseDown(with event: NSEvent) {
            mouseDownLocation = event.locationInWindow
        }
        
        var hasDraggingSession = false
        override func mouseDragged(with event: NSEvent) {
            guard !hasDraggingSession else { return }
            let distance = hypot(
                event.locationInWindow.x - mouseDownLocation.x,
                event.locationInWindow.y - mouseDownLocation.y
            )
            guard distance > 10 else { return }
            
            let promise = NSFilePromiseProvider(fileType: filePromise.type.identifier, delegate: self)
            let item = NSDraggingItem(pasteboardWriter: promise)
            item.setDraggingFrame(.init(origin: .zero, size: frame.size), contents: preview)
            beginDraggingSession(with: [item], event: event, source: self)
            hasDraggingSession = true
        }
        
        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            .copy
        }
        
        func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
            hasDraggingSession = false
        }
        
        func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
            filePromise.name
        }
        
        func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
            Task.detached { [filePromise] in
                do {
                    try await filePromise.writeToURL(url)
                    completionHandler(nil)
                } catch let error {
                    completionHandler(error)
                }
            }
        }
    }
    
    func makeNSView(context: Context) -> NSViewType {
        NSViewType(filePromise: filePromise, preview: preview)
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.filePromise = filePromise
        nsView.preview = preview
    }
}

extension View {
    func draggable(_ filePromise: FilePromise, preview: NSImage) -> some View {
        overlay(FileDragProvider(filePromise: filePromise, preview: preview))
    }
}

struct FilePromise {
    var name: String
    var type: UTType
    var writeToURL: (URL) async throws -> Void
}
