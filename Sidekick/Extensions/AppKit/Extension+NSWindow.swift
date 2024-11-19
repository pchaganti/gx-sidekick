//
//  Extension+NSWindow.swift
//  Sidekick
//
//  Created by Bean John on 11/18/24.
//

import AppKit
import Foundation

extension NSWindow.Position {
	func value(forWindow windowRect: CGRect, inScreen screenRect: CGRect) -> CGPoint {
		let xPosition = horizontal.valueFor(
			screenRange: screenRect.minX..<screenRect.maxX,
			width: windowRect.width,
			padding: padding
		)
		
		let yPosition = vertical.valueFor(
			screenRange: screenRect.minY..<screenRect.maxY,
			height: windowRect.height,
			padding: padding
		)
		
		return CGPoint(x: xPosition, y: yPosition)
	}
}

extension NSWindow.Position.Horizontal {
	func valueFor(
		screenRange: Range<CGFloat>,
		width: CGFloat,
		padding: CGFloat
	)
	-> CGFloat
	{
		switch self {
			case .left: return screenRange.lowerBound + padding
			case .center: return (screenRange.upperBound + screenRange.lowerBound - width) / 2
			case .right: return screenRange.upperBound - width - padding
		}
	}
}

extension NSWindow.Position.Vertical {
	func valueFor(
		screenRange: Range<CGFloat>,
		height: CGFloat,
		padding: CGFloat
	)
	-> CGFloat
	{
		switch self {
			case .top: return screenRange.upperBound - height - padding
			case .center: return (screenRange.upperBound + screenRange.lowerBound - height) / 2
			case .bottom: return screenRange.lowerBound + padding
		}
	}
}

public extension NSWindow.Position {
	enum Horizontal {
		case left, center, right
	}
	
	enum Vertical {
		case top, center, bottom
	}
}

public extension NSWindow {
	/// Struct to define the position of an NSWindow
	struct Position {
		public static let defaultPadding: CGFloat = 0
		public var vertical: Vertical
		public var horizontal: Horizontal
		public var padding = Self.defaultPadding
	}
	
	/// Function that sets the position of a NSWindow
	func setPosition(
		_ position: Position,
		offset: CGSize = .zero,
		in screen: NSScreen
	) {
		var origin: CGPoint = position.value(
			forWindow: self.frame,
			inScreen: screen.frame
		)
		origin.x += offset.width
		origin.y += offset.height
		self.setFrameOrigin(origin)
	}
	
	/// Function that sets the position of a NSWindow with simplified parameters
	func setPosition(
		vertical: Position.Vertical,
		horizontal: Position.Horizontal,
		offset: CGSize = .zero,
		padding: CGFloat = Position.defaultPadding,
		screen: NSScreen
	) {
		setPosition(
			Position(vertical: vertical, horizontal: horizontal, padding: padding),
			offset: offset,
			in: screen
		)
	}
}

public extension NSPanel {
	
	/// Static function that returns an NSWindow with properties appropriate for an overlay window
	static func getOverlayPanel() -> NSPanel {
		let panel = NSPanel()
		panel.standardWindowButton(.closeButton)?.isHidden = true
		panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
		panel.standardWindowButton(.zoomButton)?.isHidden = true
		panel.titleVisibility = .hidden
		panel.titlebarAppearsTransparent = true
		panel.canHide = false
		panel.isMovable = false
		panel.hasShadow = false
		panel.isReleasedWhenClosed = false
		panel.level = .mainMenu
		panel.worksWhenModal = true
		panel.hidesOnDeactivate = false
		panel.styleMask = [
			.nonactivatingPanel,
			.borderless
		]
		panel.collectionBehavior = [
			.canJoinAllSpaces,
			.fullScreenAuxiliary,
			.stationary,
			.ignoresCycle,
			.canJoinAllApplications
		]
		panel.orderFrontRegardless()
		return panel
	}
	
}
