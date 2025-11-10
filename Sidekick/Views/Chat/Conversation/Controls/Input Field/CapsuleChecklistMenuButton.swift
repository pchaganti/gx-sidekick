//
//  CapsuleChecklistMenuButton.swift
//  Sidekick
//
//  Created by John Bean on 11/10/25.
//

import SwiftUI

/// A capsule button with a checklist menu similar to SearchMenuToggleButton but with checkmarks for selection
struct CapsuleChecklistMenuButton: View {
    
    var label: String
    var systemImage: String
    var activatedFillColor: Color = .accentColor
    
    var activatedFillNSColor: NSColor {
        return self.activatedFillColor == .accentColor ? .controlAccentColor : NSColor(
            activatedFillColor
        )
    }
    
    @Binding var isActivated: Bool
    @ObservedObject var functionSelectionManager: FunctionSelectionManager
    
    @State private var anchorView: NSView?
    
    var onToggle: (Bool) -> Void
    
    var textColor: Color {
        return self.isActivated ? self.activatedFillColor : .secondary
    }
    
    var menuLabelColor: NSColor {
        return self.isActivated ? self.activatedFillNSColor : NSColor(Color.secondary)
    }
    
    var bubbleColor: Color {
        return self.isActivated ? self.activatedFillColor.opacity(0.3) : .white.opacity(0.0001)
    }
    
    var bubbleBorderColor: Color {
        return self.isActivated ? bubbleColor : .secondary
    }
    
    var body: some View {
        HStack(
            spacing: 0
        ) {
            AnchorRepresentable(view: self.$anchorView)
                .frame(width: 0.1, height: 0.1)
            buttonLeft
            Rectangle()
                .fill(self.bubbleBorderColor)
                .frame(width: 0.5, height: 22)
            menuRight
        }
        .background {
            capsule
        }
    }
    
    var buttonLeft: some View {
        Button {
            self.toggle()
        } label: {
            Label(
                self.label,
                systemImage: self.systemImage
            )
            .foregroundStyle(self.textColor)
            .font(.caption)
            .padding(5)
        }
        .buttonStyle(.plain)
    }
    
    var menuRight: some View {
        ChecklistMenuIcon(
            iconName: "chevron.down",
            color: self.menuLabelColor,
            functionSelectionManager: functionSelectionManager,
            anchorViewProvider: {
                self.anchorView
            }
        )
        .frame(width: 20, height: 20)
    }
    
    var capsule: some View {
        ZStack {
            Capsule()
                .fill(self.bubbleColor)
            Capsule()
                .stroke(
                    style: .init(
                        lineWidth: 0.3
                    )
                )
                .fill(self.bubbleBorderColor)
        }
    }
    
    private func toggle() {
        // Toggle
        withAnimation(
            .linear(duration: 0.15)
        ) {
            self.isActivated.toggle()
        }
        // Run handler
        self.onToggle(self.isActivated)
    }
}

/// Custom menu icon that presents a checklist menu
struct ChecklistMenuIcon: NSViewRepresentable {
    
    let iconName: String
    let color: NSColor
    let functionSelectionManager: FunctionSelectionManager
    let anchorViewProvider: () -> NSView?
    
    func makeNSView(
        context: Context
    ) -> NSButton {
        let button = NSButton(frame: .zero)
        button.bezelStyle = .texturedRounded
        if let image = NSImage(
            systemSymbolName: iconName,
            accessibilityDescription: nil
        ) {
            button.image = image
        }
        button.imagePosition = .imageOnly
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 6.0
        button.layer?.backgroundColor = NSColor.clear.cgColor
        button.contentTintColor = color
        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))
        button.sendAction(on: [.leftMouseDown])
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: Context) {
        // Set image and color
        nsView.image = NSImage(
            systemSymbolName: self.iconName,
            accessibilityDescription: nil
        )
        nsView.contentTintColor = color
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            functionSelectionManager: functionSelectionManager,
            anchorViewProvider: anchorViewProvider
        )
    }
    
    class Coordinator: NSObject {
        
        let functionSelectionManager: FunctionSelectionManager
        let anchorViewProvider: () -> NSView?
        
        init(
            functionSelectionManager: FunctionSelectionManager,
            anchorViewProvider: @escaping () -> NSView?
        ) {
            self.functionSelectionManager = functionSelectionManager
            self.anchorViewProvider = anchorViewProvider
        }
        
        @MainActor @objc func showMenu(
            _ sender: NSButton
        ) {
            // Create menu dynamically based on current state
            let menu = createChecklistMenu()
            
            // Present the menu just below the button
            let buttonRect = sender.bounds
            guard let anchor = self.anchorViewProvider() else {
                return
            }
            let anchorOriginInSender: CGPoint = sender.convert(
                anchor.bounds.origin,
                from: anchor
            )
            let xOffset: CGFloat = anchorOriginInSender.x
            let yOffset: CGFloat = buttonRect.midY + (buttonRect.height + 15) / 2
            let menuOrigin: NSPoint = NSPoint(
                x: xOffset,
                y: yOffset
            )
            menu.popUp(positioning: nil, at: menuOrigin, in: sender)
        }
        
        @MainActor private func createChecklistMenu() -> NSMenu {
            let menu = NSMenu()
            
            // Add menu items for each function category
            for category in FunctionCategory.allCases {
                let item = NSMenuItem(
                    title: category.description,
                    action: #selector(handleToggleCategory(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = category
                
                // Set checkmark state
                let isEnabled = functionSelectionManager.isEnabled(category)
                item.state = isEnabled ? .on : .off
                
                menu.addItem(item)
            }
            
            // Add separator
            menu.addItem(NSMenuItem.separator())
            
            // Add "Select All" option
            let selectAllItem = NSMenuItem(
                title: String(localized: "Select All"),
                action: #selector(handleSelectAll),
                keyEquivalent: ""
            )
            selectAllItem.target = self
            menu.addItem(selectAllItem)
            
            // Add "Deselect All" option
            let deselectAllItem = NSMenuItem(
                title: String(localized: "Deselect All"),
                action: #selector(handleDeselectAll),
                keyEquivalent: ""
            )
            deselectAllItem.target = self
            menu.addItem(deselectAllItem)
            
            return menu
        }
        
        @objc private func handleToggleCategory(_ sender: NSMenuItem) {
            guard let category = sender.representedObject as? FunctionCategory else {
                return
            }
            
            Task { @MainActor in
                functionSelectionManager.toggleCategory(category)
            }
        }
        
        @objc private func handleSelectAll() {
            Task { @MainActor in
                functionSelectionManager.enableAll()
            }
        }
        
        @objc private func handleDeselectAll() {
            Task { @MainActor in
                functionSelectionManager.disableAll()
            }
        }
    }
}


