//
//  CopyButton.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct CopyButton: View {
    
    var text: String
    var buttonText: String = ""
    
    private let pasteboard = NSPasteboard.general
    @State var justCopied = false
    
    var imageName: String {
        return justCopied ? "checkmark.circle.fill" : "doc.on.doc"
    }
    
    var body: some View {
        Button (
            action: copyCode
        ) {
            Group {
                if buttonText.isEmpty {
                    Image(systemName: imageName)
                        .imageScale(.medium)
                        .frame(width: 16, height: 16)
                } else {
                    Label(buttonText, systemImage: imageName)
                        .padding(.vertical, 2)
                }
            }
            .foregroundStyle(justCopied ? .green : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private func copyCode() {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        justCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            justCopied = false
        }
    }
    
}
