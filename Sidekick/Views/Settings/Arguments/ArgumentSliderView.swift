//
//  ArgumentSliderView.swift
//  Sidekick
//
//  Created by John Bean on 5/6/25.
//

import SwiftUI

struct ArgumentSliderView: View {
    
    init(
        argument: ServerArgument.CommonArgument,
        stringValue: Binding<String>
    ) {
        self.argument = argument
        self._stringValue = stringValue
        let value = Float(stringValue.wrappedValue) ?? 0
        self._floatValue = .init(initialValue: Self.roundToNearestHundredth(value))
        if Float(stringValue.wrappedValue) == nil {
            self.stringValue = "0"
        }
    }
    
    var argument: ServerArgument.CommonArgument
    @Binding var stringValue: String
    
    @FocusState private var isFocused: Bool
    @State private var floatValue: Float = 0
    
    var labelFormat: String {
        return (self.argument.type == .integer) ? "%.0f" : "%.2f"
    }
    
    public var body: some View {
        HStack {
            field
            slider
        }
        .onAppear {
            // Initialize floatValue from stringValue at start
            if let floatValue = Float(stringValue) {
                self.floatValue = Self.roundToNearestHundredth(floatValue)
                self.stringValue = formattedString(for: self.floatValue)
            }
        }
        .onChange(of: self.floatValue) {
            let roundedValue = Self.roundToNearestHundredth(
                self.floatValue
            )
            // Only update stringValue if not currently editing, to not interrupt typing
            if !isFocused {
                self.stringValue = formattedString(for: roundedValue)
            }
            // Keep floatValue always rounded
            if self.floatValue != roundedValue {
                self.floatValue = roundedValue
            }
        }
    }
    
    var field: some View {
        TextField(
            "",
            text: $stringValue
        )
        .frame(width: 60)
        .focused($isFocused)
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.leading)
        .onSubmit {
            self.syncSliderWithText()
        }
        .onChange(of: self.isFocused) {
            if !self.isFocused {
                self.syncSliderWithText()
            }
        }
    }
    
    var slider: some View {
        Slider(
            value: $floatValue,
            in: argument.range ?? 0...2
        )
    }
    
    /// Syncs the slider value from the text field, if possible, and always rounds
    private func syncSliderWithText() {
        if let newFloat = Float(stringValue) {
            let rounded = Self.roundToNearestHundredth(newFloat)
            floatValue = rounded // Will also update stringValue via onChange
            // Remove useless leading zeros immediately after editing
            stringValue = formattedString(for: rounded)
        } else {
            // If text is invalid, revert text to slider value (rounded)
            let rounded = Self.roundToNearestHundredth(floatValue)
            stringValue = formattedString(for: rounded)
        }
    }
    
    /// Rounds the given float to the nearest 0.01 (hundredth)
    private static func roundToNearestHundredth(_ value: Float) -> Float {
        (value * 100).rounded() / 100
    }
    
    /// Formats the value as a string, using int or float format, stripping useless leading zeros
    private func formattedString(for value: Float) -> String {
        if argument.type == .integer {
            return "\(Int(value))"
        } else {
            // Format to two decimal places and strip useless leading zeros
            let str = String(format: "%.2f", value)
            // Remove all leading zeros except when number is 0.xx or -0.xx
            if str.hasPrefix("-") {
                // For negative numbers, keep the single leading zero after the minus
                var s = str
                s.removeFirst() // remove "-"
                if s.hasPrefix("0") && s.count > 1 && s[s.index(s.startIndex, offsetBy: 1)] == "." {
                    return "-0" + s.dropFirst()
                } else {
                    return "-" + s.drop { $0 == "0" }
                }
            } else if str.hasPrefix("0") && str.count > 1 && str[str.index(str.startIndex, offsetBy: 1)] == "." {
                // For 0.xx keep the leading zero
                return str
            } else {
                // Otherwise remove all leading zeros
                return String(str.drop { $0 == "0" })
            }
        }
    }
    
}
