//
//  DashboardView.swift
//  Sidekick
//
//  Created by John Bean on 5/20/25.
//

import Charts
import SwiftUI

struct DashboardView: View {
    
    @StateObject private var inferenceRecords: InferenceRecords = .shared
    
    var totalTokens: Int {
        return self.inferenceRecords.filteredRecords.map { record in
            record.totalTokens
        }.reduce(0, +)
    }
    
    var totalInputTokens: Int {
        return self.inferenceRecords.filteredRecords.map { record in
            record.inputTokens
        }.reduce(0, +)
    }
    
    var totalOutputTokens: Int {
        return self.inferenceRecords.filteredRecords.map { record in
            record.outputTokens
        }.reduce(0, +)
    }
    
    var totalUsage: Int {
        return self.inferenceRecords.filteredRecords.count
    }
    
    var timeframeDescription: String {
        if self.inferenceRecords.selections.isEmpty {
            return " " + self.inferenceRecords.selectedTimeframe.description.lowercased()
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack {
            stats
                .frame(minHeight: 320)
            table
        }
        .toolbar {
            ToolbarItemGroup(
                placement: .principal
            ) {
                self.typePicker
            }
            ToolbarItemGroup(
                placement: .primaryAction
            ) {
                self.modelPicker
                self.timeframePicker
            }
        }
        .navigationTitle(Text("Dashboard"))
        .environmentObject(self.inferenceRecords)
    }
    
    var stats: some View {
        ScrollView(
            .horizontal
        ) {
            HStack {
                self.tokenUsage
                self.tokenChart
                    .frame(minWidth: 400)
                self.requestChart
                    .frame(minWidth: 400)
                self.modelChart
                    .frame(minWidth: 400)
            }
            .padding([.vertical, .leading], 10)
        }
        .scrollIndicators(.never)
    }
    
    var tokenUsage: some View {
        VStack {
            Text(String(self.totalTokens))
                .font(.system(size: 60))
                .fontDesign(.serif)
                .fontWeight(.heavy)
                .contentTransition(
                    .numericText(value: Double(self.totalTokens))
                )
            Text("tokens used\(self.timeframeDescription)")
                .font(.body)
                .contentTransition(.numericText())
            VStack {
                HStack {
                    Text("\(self.totalInputTokens) input")
                        .contentTransition(
                            .numericText(
                                value: Double(self.totalInputTokens)
                            )
                        )
                    Text("\(self.totalOutputTokens) output")
                        .contentTransition(
                            .numericText(
                                value: Double(self.totalOutputTokens)
                            )
                        )
                }
                Text("\(self.totalUsage) uses")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 5)
        }
        .padding(.horizontal, 30)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.groupBoxBackground)
                .frame(height: 300)
        }
    }
    
    var tokenChart: some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            Text("Tokens")
                .font(.title2)
                .bold()
            Chart(
                self.inferenceRecords.intervalUsage
            ) { usage in
                BarMark(
                    x: .value("Date", usage.description),
                    y: .value("Tokens", usage.tokens)
                )
                .foregroundStyle(
                    by: .value(
                        "Type",
                        usage.type.rawValue.capitalized
                    )
                )
            }
        }
        .frame(maxWidth: 300, maxHeight: 280)
        .padding(.horizontal, 30)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.groupBoxBackground)
                .frame(height: 300)
        }
    }
    
    var requestChart: some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            Text("Usage")
                .font(.title2)
                .bold()
            Chart(
                self.inferenceRecords.intervalUsage
            ) { usage in
                BarMark(
                    x: .value("Date", usage.description),
                    y: .value("Uses", usage.uses)
                )
            }
        }
        .frame(maxWidth: 300, maxHeight: 280)
        .padding(.horizontal, 30)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.groupBoxBackground)
                .frame(height: 300)
        }
    }
    
    var modelChart: some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            Text("Models")
                .font(.title2)
                .bold()
            Chart(
                self.inferenceRecords.modelUsage
            ) { usage in
                BarMark(
                    x: .value("Model", usage.model),
                    y: .value("Tokens", usage.tokens)
                )
                .foregroundStyle(
                    by: .value(
                        "Type",
                        usage.type.rawValue.capitalized
                    )
                )
            }
        }
        .frame(maxWidth: 300, maxHeight: 280)
        .padding(.horizontal, 30)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.groupBoxBackground)
                .frame(height: 300)
        }
    }
    
    var table: some View {
        Table(
            self.inferenceRecords.displayedRecords,
            selection: self.$inferenceRecords.selections
        ) {
            TableColumn("Start Time") { record in
                Text(record.startTime.formatted(.dateTime))
            }
            TableColumn("End Time") { record in
                Text(record.endTime.formatted(.dateTime))
            }
            TableColumn("Duration") { record in
                Text("\(String(format: "%.1f", record.duration)) s")
            }
            TableColumn("Model") { record in
                HStack {
                    PopoverButton {
                        Circle()
                            .fill(record.usedRemoteServer ? Color.blue : Color.green)
                            .frame(width: 10, height: 10)
                    } content: {
                        Text(record.usedRemoteServer ? String(localized :"Remote Inference") : String(localized :"Local Inference"))
                            .padding(7)
                    }
                    .buttonStyle(.plain)
                    Text(record.name)
                }
            }
            TableColumn(
                "Type"
            ) { record in
                Text(record.type.description)
            }
            TableColumn(
                "Input Tokens"
            ) { record in
                Text(String(record.inputTokens))
            }
            TableColumn(
                "Output Tokens"
            ) { record in
                Text(String(record.outputTokens))
            }
            TableColumn(
                "Total Tokens"
            ) { record in
                Text(String(record.totalTokens))
            }
            TableColumn(
                "Speed (t/s)"
            ) { record in
                Text("\(String(format: "%.1f", record.tokensPerSecond)) t/s")
            }
        }
    }
    
    var typePicker: some View {
        Picker(
            selection: self.$inferenceRecords.selectedType.animation(
                .linear
            )
        ) {
            ForEach(
                InferenceRecord.UsageType.allCases,
                id: \.self
            ) { type in
                Text(type.description)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var modelPicker: some View {
        Picker(
            selection: self.$inferenceRecords.selectedModel.animation(
                .linear
            )
        ) {
            Text("All Models")
                .tag(String?(nil))
            ForEach(
                self.inferenceRecords.models,
                id: \.self
            ) { model in
                Text(model)
                    .tag(model)
            }
        }
        .pickerStyle(.menu)
    }
    
    var timeframePicker: some View {
        Picker(
            selection: self.$inferenceRecords.selectedTimeframe.animation(
                .linear
            )
        ) {
            ForEach(
                InferenceRecords.Timeframe.allCases,
                id: \.self
            ) { timeframe in
                Text(timeframe.description)
                    .tag(timeframe)
            }
        }
        .pickerStyle(.menu)
    }
    
}

#Preview {
    DashboardView()
}
