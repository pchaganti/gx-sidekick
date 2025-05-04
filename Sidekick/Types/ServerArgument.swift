//
//  ServerArgument.swift
//  Sidekick
//
//  Created by John Bean on 4/29/25.
//

import Foundation
import SwiftUI

public struct ServerArgument: Identifiable, Codable, Equatable {
    
    public var id: UUID = UUID()
    
    /// A `Bool` representing whether the argument is active
    public var isActive: Bool = true
    /// A `String` containing the flag
    public var flag: String
    /// A `String` containing a value corresponding to the flag
    public var value: String
    
    /// The arguments to be appended to `llama-server`
    public var arguments: [String] {
        var arguments: [String] = [self.flag]
        if !self.value.isEmpty {
            arguments.append(self.value)
        }
        return arguments
    }
    
    /// A list of default arguments
    public static let defaultServerArguments: [ServerArgument] = [
        ServerArgument(
            flag: "--top-k",
            value: "20"
        ),
        ServerArgument(
            flag: "--top-p",
            value: "0.95"
        ),
        ServerArgument(
            flag: "--min-p",
            value: "0"
        ),
        ServerArgument(
            flag: "--presence-penalty",
            value: "1.5"
        )
    ]
    
    public struct ArgumentSliderView: View {
        init(
            argument: CommonArgument,
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
        
        var argument: CommonArgument
        @Binding var stringValue: String
        
        @FocusState private var isFocused: Bool
        @State private var floatValue: Float = 0
        
        var labelFormat: String {
            argument.isInt ? "%.0f" : "%.2f"
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
                in: argument.range
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
            if argument.isInt {
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
    
    public struct CommonArgument: Hashable {
        
        init(
            flag: String,
            name: String,
            description: String,
            range: ClosedRange<Float>,
            isInt: Bool = false
        ) {
            self.flag = flag
            self.name = name
            self.description = description
            self.range = range
            self.isInt = isInt
        }
        
        init?(
            flag: String
        ) {
            for argument in CommonArgument.commonArguments {
                if argument.flag == flag {
                    self = argument
                    return
                }
            }
            return nil
        }
                
        var name: String
        var description: String
        
        var label: some View {
            HStack {
                Text(self.name)
                PopoverButton {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                } content: {
                    Text(description)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .frame(
                            minWidth: 200,
                            maxHeight: 300
                        )
                        .padding(7)
                }
                .buttonStyle(.plain)
            }
        }
        
        var flag: String
        var range: ClosedRange<Float>
        var isInt: Bool
        
        static let commonArguments: [CommonArgument] = [
            CommonArgument(
                flag: "--top-k",
                name: "Top K",
                description: "Limits the next-token selection to the top K most likely tokens. A higher value increases diversity but may reduce coherence.",
                range: 0...100,
                isInt: true
            ),
            CommonArgument(
                flag: "--top-p",
                name: "Top P",
                description: "Enables nucleus sampling by considering the smallest set of tokens whose cumulative probability exceeds P. Balances diversity and relevance.",
                range: 0...1
            ),
            CommonArgument(
                flag: "--min-p",
                name: "Min P",
                description: "Sets the minimum probability threshold for candidate tokens, excluding those with lower probabilities from selection.",
                range: 0...1
            ),
            CommonArgument(
                flag: "--presence-penalty",
                name: "Presence Penalty",
                description: "Increases the model’s likelihood to select new tokens by penalizing tokens that have already appeared in the generated text.",
                range: 0...2
            ),
            CommonArgument(
                flag: "--repeat-penalty",
                name: "Repeat Penalty",
                description: "Penalizes repeated tokens in the generated text.",
                range: 0...2
            )
        ]
        
    }
    
}
