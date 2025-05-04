//
//  ServerArgumentsEditor.swift
//  Sidekick
//
//  Created by John Bean on 4/29/25.
//

import SwiftUI

struct ServerArgumentsEditor: View {
    
    @Binding var isPresented: Bool
    
    @StateObject private var serverArgumentsManager: ServerArgumentsManager = .shared
    @State private var selections = Set<ServerArgument.ID>()
    
    var body: some View {
        VStack {
            table
                .padding(.horizontal, 12)
            Divider()
            bottomBar
        }
        .padding(.vertical, 12)
    }
    
    var bottomBar: some View {
        HStack {
            Link(
                "Docs",
                destination: URL(
                    string: "https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md"
                )!
            )
            Spacer()
            addButton
            doneButton
        }
        .controlSize(.large)
        .padding(.horizontal, 12)
    }
    
    var addButton: some View {
        Button {
            // Add
            withAnimation(.linear) {
                let blankArgument = ServerArgument(flag: "", value: "")
                self.serverArgumentsManager.add(blankArgument)
            }
        } label: {
            Text("Add")
        }
    }
    
    var doneButton: some View {
        Button {
            // Send notification to reload model
            NotificationCenter.default.post(
                name: Notifications.changedInferenceConfig.name,
                object: nil
            )
            // Exit
            withAnimation(.linear) {
                self.isPresented.toggle()
            }
        } label: {
            Text("Done")
        }
    }
    
    var table: some View {
        Table(
            of: Binding<ServerArgument>.self,
            selection: self.$selections
        ) {
            // Field for toggling status of argument
            TableColumn("Active") { argument in
                Toggle(isOn: argument.isActive, label: {})
                    .toggleStyle(.checkbox)
            }
            .width(max: 65)
            // Field for value
            TableColumn("Flag") { argument in
                TextField(text: argument.flag, label: {})
            }
            // Field for value
            TableColumn("Value") { argument in
                TextField(text: argument.value, label: {})
            }
        } rows: {
            ForEach(
                self.$serverArgumentsManager.serverArguments
            ) { argument in
                TableRow(argument)
                    .contextMenu {
                        Button {
                            self.serverArgumentsManager.delete(argument)
                        } label: {
                            Text("Delete")
                        }
                    }
            }
        }
    }
    
}
