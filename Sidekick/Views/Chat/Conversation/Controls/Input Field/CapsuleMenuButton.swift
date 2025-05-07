//
//  CapsuleMenuButton.swift
//  Sidekick
//
//  Created by John Bean on 5/7/25.
//

import SwiftUI

struct CapsuleMenuButton<Options: MenuOptions>: View {
    
    var systemImage: String
    var activatedFillColor: Color = .accentColor
    
    var activatedFillNSColor: NSColor {
        return self.activatedFillColor == .accentColor ? .controlAccentColor : NSColor(
            activatedFillColor
        )
    }
    
    @State private var isShowingSelection: Bool = false
    
    @Binding var isActivated: Bool
    @Binding var selectedOption: Options
    
    @State private var anchorView: NSView?
    
    var onToggle: (Bool) -> Void
    var onSelectionChange: ((Options) -> Void) = { _ in }
    
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
    
    var options: [Options] {
        return (Options.allCases as? [Options]) ?? []
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
                self.selectedOption.description,
                systemImage: self.systemImage
            )
            .foregroundStyle(self.textColor)
            .font(.caption)
            .padding(5)
        }
        .buttonStyle(.plain)
    }
    
    var menuRight: some View {
        MenuIcon(
            iconName: "chevron.down",
            color: self.menuLabelColor,
            menu: NSMenu.fromOptions(
                options: self.options
            ) { option in
                self.changeSelection(newSelection: option)
            },
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
    
    private func changeSelection(
        newSelection: Options
    ) {
        // Toggle
        withAnimation(
            .linear(duration: 0.15)
        ) {
            // Check if did change
            let didChange: Bool = self.selectedOption != newSelection
            self.selectedOption = newSelection
            // If did change
            if didChange {
                self.isActivated = true
            } else {
                // Else, toggle
                self.isActivated.toggle()
            }
        }
        // Run handler
        self.onSelectionChange(newSelection)
    }
    
}

protocol MenuOptions: Identifiable, Equatable, CaseIterable {
    var description: String { get }
}

struct MenuIcon: NSViewRepresentable {
    
    let iconName: String
    let color: NSColor
    let menu: NSMenu
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
            menu: menu,
            anchorViewProvider: anchorViewProvider
        )
    }
    
    class Coordinator: NSObject {
        
        let menu: NSMenu
        let anchorViewProvider: () -> NSView?
        
        init(
            menu: NSMenu,
            anchorViewProvider: @escaping () -> NSView?
        ) {
            self.menu = menu
            self.anchorViewProvider = anchorViewProvider
        }
        
        @objc func showMenu(
            _ sender: NSButton
        ) {
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
        
    }
}

extension NSMenu {
    
    static func fromOptions<Options: MenuOptions>(
        options: [Options],
        selectionHandler: @escaping (Options) -> Void
    ) -> NSMenu {
        let menu = NSMenu()
        for option in options {
            let item = NSMenuItem(
                title: option.description,
                action: #selector(MenuHandler.handleMenu(_:)),
                keyEquivalent: ""
            )
            item.target = MenuHandler.shared
            item.representedObject = MenuHandler.OptionWrapper(
                option: option,
                handler: { anyOption in
                    if let typedOption = anyOption as? Options {
                        selectionHandler(typedOption)
                    }
                }
            )
            menu.addItem(item)
        }
        return menu
    }
    
}

/// Helper class to bring Swift closures to AppKit actions
fileprivate class MenuHandler: NSObject {
    
    static let shared = MenuHandler()
    
    struct OptionWrapper {
        let option: any MenuOptions
        let handler: (any MenuOptions) -> Void
    }
    
    @objc func handleMenu(
        _ sender: NSMenuItem
    ) {
        if let wrapper = sender.representedObject as? OptionWrapper {
            wrapper.handler(wrapper.option)
        }
    }
}

struct AnchorRepresentable: NSViewRepresentable {
    
    @Binding var view: NSView?
    
    func makeNSView(
        context: Context
    ) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.view = view }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
}
