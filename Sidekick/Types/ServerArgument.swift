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
    public var isActive: Bool = false
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
            flag: "--flash-attn",
            value: ""
        ),
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
        ),
        ServerArgument(
            flag: "--cache-type-k",
            value: "f16"
        ),
        ServerArgument(
            flag: "--cache-type-v",
            value: "f16"
        )
    ]
    
    public struct CommonArgument: Hashable {
        
        init(
            flag: String,
            name: String,
            description: String,
            type: `Type`,
            range: ClosedRange<Float>? = nil,
            values: [String]? = nil
        ) {
            self.flag = flag
            self.name = name
            self.description = description
            self.range = range
            self.values = values
            self.type = type
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
        var type: `Type`
        
        var range: ClosedRange<Float>?
        var values: [String]?
        
        static let commonArguments: [CommonArgument] = [
            CommonArgument(
                flag: "--flash-attn",
                name: "Flash Attention",
                description: "Flash Attention speeds up transformer attention by processing smaller blocks, reducing memory use and data transfer.",
                type: .null
            ),
            CommonArgument(
                flag: "--top-k",
                name: "Top K",
                description: "Limits the next-token selection to the top K most likely tokens. A higher value increases diversity but may reduce coherence.",
                type: .integer,
                range: 0...100
            ),
            CommonArgument(
                flag: "--top-p",
                name: "Top P",
                description: "Enables nucleus sampling by considering the smallest set of tokens whose cumulative probability exceeds P. Balances diversity and relevance.",
                type: .float,
                range: 0...1
            ),
            CommonArgument(
                flag: "--min-p",
                name: "Min P",
                description: "Sets the minimum probability threshold for candidate tokens, excluding those with lower probabilities from selection.",
                type: .float,
                range: 0...1
            ),
            CommonArgument(
                flag: "--presence-penalty",
                name: "Presence Penalty",
                description: "Increases the model’s likelihood to select new tokens by penalizing tokens that have aready appeared in the generated text.",
                type: .float,
                range: 0...2
            ),
            CommonArgument(
                flag: "--repeat-penalty",
                name: "Repeat Penalty",
                description: "Penalizes repeated tokens in the generated text.",
                type: .float,
                range: 0...2
            ),
            CommonArgument(
                flag: "--cache-type-k",
                name: "KV Cache Type for K",
                description: "The data type of the keys in the KV cache.",
                type: .string,
                values: ["f32", "f16", "bf16", "q8_0", "q4_0", "q4_1", "iq4_nl", "q5_0", "q5_1"]
            ),
            CommonArgument(
                flag: "--cache-type-v",
                name: "KV Cache Type for V",
                description: "The data type of the keys in the KV cache.",
                type: .string,
                values: ["f32", "f16", "bf16", "q8_0", "q4_0", "q4_1", "iq4_nl", "q5_0", "q5_1"]
            )
        ]
        
        public enum `Type`: String, CaseIterable {
            
            case integer, float, string, null
            
            var isNumeric: Bool {
                switch self {
                    case .integer, .float:
                        return true
                    default:
                        return false
                }
            }
            
        }
        
        func getEditor(
            stringValue: Binding<String>
        ) -> some View {
            Group {
                switch self.type {
                    case .integer, .float:
                        ArgumentSliderView(
                            argument: self,
                            stringValue: stringValue
                        )
                    case .string:
                        ArgumentPickerView(
                            argument: self,
                            stringValue: stringValue
                        )
                    case .null:
                        Spacer()
                            .padding(.vertical, 3)
                }
            }
        }
        
    }
    
}
