//
//  EndDetectionScrollView.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct EndDetectionScrollView<Content: View>: View {
	
	let axis: Axis.Set
	let showIndicators: Bool
	@Binding var hasScrolledNearEnd: Bool
	let distanceFromEnd: CGFloat
	let content: () -> Content
	
	@State private var visibleContentHeight: CGFloat = 0
	@State private var totalContentHeight: CGFloat = 0
	
	init(_ axis: Axis.Set,
		 showIndicators: Bool,
		 hasScrolledNearEnd: Binding<Bool>,
		 distanceFromEnd: CGFloat = 100,
		 @ViewBuilder content: @escaping () -> Content) {
		self.content = content
		self.axis = axis
		self.showIndicators = showIndicators
		self.distanceFromEnd = distanceFromEnd
		self._hasScrolledNearEnd = hasScrolledNearEnd
	}
	
	var body: some View {
		ScrollView(axis, showsIndicators: showIndicators) {
			offsetReader
			content()
				.overlay(content:  {
					GeometryReader(content: { geometry in
						Color.clear.onAppear {
							self.totalContentHeight = geometry.frame(in: .global).height
						}
					})
				})
			
		}
		.overlay(content:  {
			GeometryReader(content: { geometry in
				Color.clear.onAppear {
					self.visibleContentHeight = geometry.frame(in: .global).height
				}
			})
		})
		.coordinateSpace(name: "frameLayer")
		.onPreferenceChange(OffsetPreferenceKey.self, perform: { offset in
			if totalContentHeight < visibleContentHeight {
				hasScrolledNearEnd = true
				return
			}
			if totalContentHeight != 0 && visibleContentHeight != 0 {
				if (totalContentHeight - visibleContentHeight) + offset <= distanceFromEnd {
					hasScrolledNearEnd = true
				} else {
					hasScrolledNearEnd = false
				}
			} else {
				hasScrolledNearEnd = false
			}
		})
	}
	
	var offsetReader: some View {
		GeometryReader { proxy in
			Color.clear
				.preference(
					key: OffsetPreferenceKey.self,
					value: proxy.frame(in: .named("frameLayer")).maxY
				)
		}
		.frame(height: 0)
	}
	
}

struct OffsetPreferenceKey: PreferenceKey {
	@MainActor static var defaultValue: CGFloat = .zero
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
