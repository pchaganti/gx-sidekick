//
//  FunctionCallsView.swift
//  Sidekick
//
//  Created by John Bean on 4/9/25.
//

import SwiftUI

struct FunctionCallsView: View {
    
    var message: Message
    
    var functionCalls: [FunctionCall] {
        return self.message.functionCalls ?? []
    }
    
    var body: some View {
        ForEach(
            functionCalls,
            id: \.self
        ) { call in
            FunctionCallView(functionCall: call)
        }
    }
    
    struct FunctionCallView: View {
        
        @State private var showDetails: Bool = false
        
        var functionCall: FunctionCall
        var boxColor: Color {
            return self.functionCall.status?.color ?? .secondary
        }
        
        var body: some View {
            Button {
                withAnimation(.linear) {
                    self.showDetails.toggle()
                }
            } label: {
                label
            }
            .buttonStyle(.plain)
        }
        
        var label: some View {
            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                labelContent
                    .frame(height: 33)
                if self.showDetails {
                    Divider()
                    details
                }
            }
            .background {
                Group {
                    if boxColor == .secondary {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(boxColor.opacity(0.8))
                    } else {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(boxColor.opacity(0.2))
                    }
                }
            }
        }
        
        var labelContent: some View {
            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(
                        self.functionCall.status?.color ?? .gray
                    )
                    .padding(.horizontal, 5)
                Group {
                    Text("Function: ").bold() + Text(self.functionCall.config.name).italic()
                }
                .opacity(0.8)
                Spacer()
                Image(systemName: "chevron.up")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary.opacity(0.8))
                    .rotationEffect(
                        self.showDetails ? .zero : .degrees(180)
                    )
            }
            .padding(.horizontal, 7)
        }
        
        var details: some View {
            VStack(alignment: .leading) {
                Text("Call: ").bold() + Text(self.functionCall.getJsonSchema()).italic()
                if let result = self.functionCall.result {
                    Text("Result: ").bold() + Text(result).italic()
                }
            }
            .opacity(0.9)
            .padding(.horizontal, 9)
            .padding(.vertical, 9)
        }
        
    }
    
}
