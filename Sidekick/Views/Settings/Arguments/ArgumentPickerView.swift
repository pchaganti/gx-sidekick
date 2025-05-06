//
//  ArgumentPickerView.swift
//  Sidekick
//
//  Created by John Bean on 5/6/25.
//

import SwiftUI

struct ArgumentPickerView: View {
    
    init(
        argument: ServerArgument.CommonArgument,
        stringValue: Binding<String>
    ) {
        self.argument = argument
        self._stringValue = stringValue
    }
    
    var argument: ServerArgument.CommonArgument
    @Binding var stringValue: String
    
    var options: [String] {
        return argument.values ?? []
    }
    
    public var body: some View {
        Picker(
            selection: $stringValue
        ) {
            ForEach(
                options,
                id: \.self
            ) { option in
                Text(option)
                    .tag(option)
            }
        }
        .pickerStyle(.menu)
        .padding(.vertical, 2)
    }
    
}
