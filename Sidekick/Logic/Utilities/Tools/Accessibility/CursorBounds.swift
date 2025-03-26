//
//  CursorBounds.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//

import SwiftUI
import OSLog

public class CursorBounds {

    public init() {}
    
    public func getOrigin(
        correctionMode: ScreenCorrectionMode = .adjustForYAxis,
        xCorner: BoundsCornerX = .minX,
        yCorner: BoundsCornerY = .minY
    ) -> Origin? {
		guard let focusedElement = ActiveApplicationInspector.getFocusedElement(),
              let cursorPositionResult = focusedElement.resolveCursorPosition() else {
            return nil
        }
        // Find which screen contains the caret’s origin
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(cursorPositionResult.bounds.origin) }) else {
            return nil
        }
        // Get the X-coordinate based on the specified corner
        let xCoordinate: CGFloat
		switch xCorner {
			case .minX:
				xCoordinate = cursorPositionResult.bounds.minX
			case .maxX:
				xCoordinate = cursorPositionResult.bounds.maxX
		}
        // Get the Y-coordinate based on the specified corner
        let yCoordinate: CGFloat
		switch yCorner {
			case .minY:
				yCoordinate = cursorPositionResult.bounds.minY
			case .maxY:
				yCoordinate = cursorPositionResult.bounds.maxY
		}
        // Apply Y-axis correction if necessary
        let correctedY: CGFloat
        switch correctionMode {
        case .none:
            correctedY = yCoordinate
        case .adjustForYAxis:
            // We can work with either the full screen’s frame or just its visibleFrame.
            // visibleFrame excludes the Dock and Menu Bar areas, whereas frame does not, we need to consider the whole screen for our case (I've tested this and this works best, although feedback is welcome)
            correctedY = screen.frame.maxY - yCoordinate
        }
        return Origin(type: cursorPositionResult.type, NSPoint: NSPoint(x: xCoordinate, y: correctedY))
    }
	
}

public class CursorBoundsConfig {
    public static var shared = CursorBoundsConfig()
    public var logLevel: LogLevel = .info
    
    private init() {} // Prevent external instantiation
}
