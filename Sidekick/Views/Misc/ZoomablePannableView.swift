//
//  ZoomablePannableView.swift
//  Sidekick
//
//  Created by John Bean on 4/27/25.
//

import SwiftUI

struct ZoomablePannableView<Content: View>: View {
    
    @State private var hoverLocation: CGPoint = .zero
    
    @State private var scale: CGFloat = 1.0
    @State private var initialScale: CGFloat = 1.0
    
    @State private var offset: CGSize = .zero
    @State private var initialOffset: CGSize = .zero
    
    let content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            content()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    zoomGesture
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                        initialOffset = .zero
                    }
                }
                .animation(.easeInOut, value: scale)
        }
        .overlay(
            alignment: .bottomTrailing
        ) {
            gamepad
                .padding([.bottom, .trailing], 6)
        }
    }
    
    var gamepad: some View {
        GeometryReader { geometry in
            Image(systemName: "square.arrowtriangle.4.outward")
                .padding(7)
                .background {
                    Circle()
                        .fill(Color(nsColor: .darkGray))
                }
                .onTapGesture { location in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let x = location.x
                    let y = location.y
                    let isLeft = x < width / 2
                    let isTop = y < height / 2
                    let increment: CGFloat = 100
                    withAnimation(.linear) {
                        switch (isLeft, isTop) {
                            case (true, true):
                                offset.height += increment
                            case (false, true):
                                offset.width -= increment
                            case (true, false):
                                offset.width += increment
                            case (false, false):
                                offset.height -= increment
                        }
                    }
                }
        }
        .rotationEffect(.degrees(45))
        .frame(maxWidth: 30, maxHeight: 30)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                offset = CGSize(
                    width: initialOffset.width + gesture.translation.width,
                    height: initialOffset.height + gesture.translation.height
                )
            }
            .onEnded { _ in
                initialOffset = offset
            }
    }
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                self.scale = max(1.0, self.initialScale * value)
            }
            .onEnded { _ in
                self.scale = max(1.0, self.scale)
                self.initialScale = self.scale
            }
    }
    
}
