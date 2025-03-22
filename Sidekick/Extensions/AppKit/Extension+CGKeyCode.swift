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

	static let kVK_ANSI_A                    : CGKeyCode = 0x00
	static let kVK_ANSI_S                    : CGKeyCode = 0x01
	static let kVK_ANSI_D                    : CGKeyCode = 0x02
	static let kVK_ANSI_F                    : CGKeyCode = 0x03
	static let kVK_ANSI_H                    : CGKeyCode = 0x04
	static let kVK_ANSI_G                    : CGKeyCode = 0x05
	static let kVK_ANSI_Z                    : CGKeyCode = 0x06
	static let kVK_ANSI_X                    : CGKeyCode = 0x07
	static let kVK_ANSI_C                    : CGKeyCode = 0x08
	static let kVK_ANSI_V                    : CGKeyCode = 0x09
	static let kVK_ANSI_B                    : CGKeyCode = 0x0B
	static let kVK_ANSI_Q                    : CGKeyCode = 0x0C
	static let kVK_ANSI_W                    : CGKeyCode = 0x0D
	static let kVK_ANSI_E                    : CGKeyCode = 0x0E
	static let kVK_ANSI_R                    : CGKeyCode = 0x0F
	static let kVK_ANSI_Y                    : CGKeyCode = 0x10
	static let kVK_ANSI_T                    : CGKeyCode = 0x11
	static let kVK_ANSI_1                    : CGKeyCode = 0x12
	static let kVK_ANSI_2                    : CGKeyCode = 0x13
	static let kVK_ANSI_3                    : CGKeyCode = 0x14
	static let kVK_ANSI_4                    : CGKeyCode = 0x15
	static let kVK_ANSI_6                    : CGKeyCode = 0x16
	static let kVK_ANSI_5                    : CGKeyCode = 0x17
	static let kVK_ANSI_Equal                : CGKeyCode = 0x18
	static let kVK_ANSI_9                    : CGKeyCode = 0x19
	static let kVK_ANSI_7                    : CGKeyCode = 0x1A
	static let kVK_ANSI_Minus                : CGKeyCode = 0x1B
	static let kVK_ANSI_8                    : CGKeyCode = 0x1C
	static let kVK_ANSI_0                    : CGKeyCode = 0x1D
	static let kVK_ANSI_RightBracket         : CGKeyCode = 0x1E
	static let kVK_ANSI_O                    : CGKeyCode = 0x1F
	static let kVK_ANSI_U                    : CGKeyCode = 0x20
	static let kVK_ANSI_LeftBracket          : CGKeyCode = 0x21
	static let kVK_ANSI_I                    : CGKeyCode = 0x22
	static let kVK_ANSI_P                    : CGKeyCode = 0x23
	static let kVK_ANSI_L                    : CGKeyCode = 0x25
	static let kVK_ANSI_J                    : CGKeyCode = 0x26
	static let kVK_ANSI_Quote                : CGKeyCode = 0x27
	static let kVK_ANSI_K                    : CGKeyCode = 0x28
	static let kVK_ANSI_Semicolon            : CGKeyCode = 0x29
	static let kVK_ANSI_Backslash            : CGKeyCode = 0x2A
	static let kVK_ANSI_Comma                : CGKeyCode = 0x2B
	static let kVK_ANSI_Slash                : CGKeyCode = 0x2C
	static let kVK_ANSI_N                    : CGKeyCode = 0x2D
	static let kVK_ANSI_M                    : CGKeyCode = 0x2E
	static let kVK_ANSI_Period               : CGKeyCode = 0x2F
	static let kVK_ANSI_Grave                : CGKeyCode = 0x32
	static let kVK_ANSI_KeypadDecimal        : CGKeyCode = 0x41
	static let kVK_ANSI_KeypadMultiply       : CGKeyCode = 0x43
	static let kVK_ANSI_KeypadPlus           : CGKeyCode = 0x45
	static let kVK_ANSI_KeypadClear          : CGKeyCode = 0x47
	static let kVK_ANSI_KeypadDivide         : CGKeyCode = 0x4B
	static let kVK_ANSI_KeypadEnter          : CGKeyCode = 0x4C
	static let kVK_ANSI_KeypadMinus          : CGKeyCode = 0x4E
	static let kVK_ANSI_KeypadEquals         : CGKeyCode = 0x51
	static let kVK_ANSI_Keypad0              : CGKeyCode = 0x52
	static let kVK_ANSI_Keypad1              : CGKeyCode = 0x53
	static let kVK_ANSI_Keypad2              : CGKeyCode = 0x54
	static let kVK_ANSI_Keypad3              : CGKeyCode = 0x55
	static let kVK_ANSI_Keypad4              : CGKeyCode = 0x56
	static let kVK_ANSI_Keypad5              : CGKeyCode = 0x57
	static let kVK_ANSI_Keypad6              : CGKeyCode = 0x58
	static let kVK_ANSI_Keypad7              : CGKeyCode = 0x59
	static let kVK_ANSI_Keypad8              : CGKeyCode = 0x5B
	static let kVK_ANSI_Keypad9              : CGKeyCode = 0x5C
	
	/// Static property containing all key codes
	static var allKeys: [CGKeyCode] = [
		kVK_Command,
		kVK_Control,
		kVK_Shift,
		kVK_Option,
		kVK_Function,
		kVK_Escape,
		kVK_ANSI_A,
		kVK_ANSI_S,
		kVK_ANSI_D,
		kVK_ANSI_F,
		kVK_ANSI_H,
		kVK_ANSI_G,
		kVK_ANSI_Z,
		kVK_ANSI_X,
		kVK_ANSI_C,
		kVK_ANSI_V,
		kVK_ANSI_B,
		kVK_ANSI_Q,
		kVK_ANSI_W,
		kVK_ANSI_E,
		kVK_ANSI_R,
		kVK_ANSI_Y,
		kVK_ANSI_T,
		kVK_ANSI_1,
		kVK_ANSI_2,
		kVK_ANSI_3,
		kVK_ANSI_4,
		kVK_ANSI_6,
		kVK_ANSI_5,
		kVK_ANSI_Equal,
		kVK_ANSI_9,
		kVK_ANSI_7,
		kVK_ANSI_Minus,
		kVK_ANSI_8,
		kVK_ANSI_0,
		kVK_ANSI_RightBracket,
		kVK_ANSI_O,
		kVK_ANSI_U,
		kVK_ANSI_LeftBracket,
		kVK_ANSI_I,
		kVK_ANSI_P,
		kVK_ANSI_L,
		kVK_ANSI_J,
		kVK_ANSI_Quote,
		kVK_ANSI_K,
		kVK_ANSI_Semicolon,
		kVK_ANSI_Backslash,
		kVK_ANSI_Comma,
		kVK_ANSI_Slash,
		kVK_ANSI_N,
		kVK_ANSI_M,
		kVK_ANSI_Period,
		kVK_ANSI_Grave,
		kVK_ANSI_KeypadDecimal,
		kVK_ANSI_KeypadMultiply,
		kVK_ANSI_KeypadPlus,
		kVK_ANSI_KeypadClear,
		kVK_ANSI_KeypadDivide,
		kVK_ANSI_KeypadEnter,
		kVK_ANSI_KeypadMinus,
		kVK_ANSI_KeypadEquals,
		kVK_ANSI_Keypad0,
		kVK_ANSI_Keypad1,
		kVK_ANSI_Keypad2,
		kVK_ANSI_Keypad3,
		kVK_ANSI_Keypad4,
		kVK_ANSI_Keypad5,
		kVK_ANSI_Keypad6,
		kVK_ANSI_Keypad7,
		kVK_ANSI_Keypad8,
		kVK_ANSI_Keypad9
	]
	
	/// Computed property returning whether the key is pressed
	var isPressed: Bool {
		CGEventSource.keyState(.combinedSessionState, key: self)
	}
	
	/// Function to return keycode for character
	func keycode(for character: Character) -> CGKeyCode? {
		switch character {
			case "1": return .kVK_ANSI_1
			case "2": return .kVK_ANSI_2
			case "3": return .kVK_ANSI_3
			case "4": return .kVK_ANSI_4
			case "5": return .kVK_ANSI_5
			case "6": return .kVK_ANSI_6
			case "7": return .kVK_ANSI_7
			case "8": return .kVK_ANSI_8
			case "9": return .kVK_ANSI_9
			case "0": return .kVK_ANSI_0
			default: return nil
		}
	}
	
}
