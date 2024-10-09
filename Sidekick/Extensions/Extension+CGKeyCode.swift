//
//  Extension+CGKeyCode.swift
//  Sidekick
//
//  Created by Bean John on 10/8/24.
//

import Foundation
import CoreGraphics

public extension CGKeyCode {
	
	/// Static constant for the `Command` key's key code
	static let kVK_Command: CGKeyCode = 0x37
	
	/// Static constant for the `Control` key's key code
	static let kVK_Control: CGKeyCode = 0x3B
	
	/// Static constant for the `Shift` key's key code
	static let kVK_Shift: CGKeyCode = 0x38
	
	/// Static constant for the `Option` key's key code
	static let kVK_Option: CGKeyCode = 0x3A
	
	/// Static constant for the `Function` key's key code
	static let kVK_Function: CGKeyCode = 0x3F
	
	/// Static constant for the `Escape` key's key code
	static let kVK_Escape: CGKeyCode = 0x35

	
	/// Computed property returning whether the key is pressed
	var isPressed: Bool {
		CGEventSource.keyState(.combinedSessionState, key: self)
	}
	
}
