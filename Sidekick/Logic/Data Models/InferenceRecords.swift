//
//  InferenceRecords.swift
//  Sidekick
//
//  Created by John Bean on 5/20/25.
//

import Charts
import Foundation
import FSKit_macOS
import os.log
import SwiftUI
import UniformTypeIdentifiers

public class InferenceRecords: ObservableObject {
    
    init() {
        self.patchFileIntegrity()
        self.load()
    }
    
    /// Static constant for the global ``InferenceRecords`` object
    static public let shared: InferenceRecords = .init()
    
    @Published var records: [InferenceRecord] = [] {
        didSet {
            self.save()
        }
    }
    // Table config
    @Published public var selections = Set<InferenceRecord.ID>()
    private var selectedRecords: [InferenceRecord] {
        return self.records.filter { record in
            return self.selections.contains(record.id)
        }
    }
    
    /// All records within the timeframe & with the selected model
    public var displayedRecords: [InferenceRecord] {
        // Filter and return
        let timelyRecords = self.records.filter { record in
            return self.selectedTimeframe.range.contains(record.startTime) || self.selectedTimeframe.range.contains(record.endTime)
        }
        if let selectedModel {
            return timelyRecords.filter { record in
                return record.name == selectedModel
            }
        } else {
            return timelyRecords
        }
    }
    
    /// All records within the timeframe & with the selected model
    public var filteredRecords: [InferenceRecord] {
        // Return selection if selected
        var records = self.records
        if !self.selectedRecords.isEmpty {
            records = self.selectedRecords
        }
        // Else, filter
        let timelyRecords = records.filter { record in
            return self.selectedTimeframe.range.contains(record.startTime) || self.selectedTimeframe.range.contains(record.endTime)
        }
        if let selectedModel {
            return timelyRecords.filter { record in
                return record.name == selectedModel
            }
        } else {
            return timelyRecords
        }
    }
    
    /// The currently selected model
    @Published public var selectedModel: String? = nil
    /// The currently selected timeframe
    @Published public var selectedTimeframe: Timeframe = .today
    
    public var intervalUsage: [IntervalUse] {
        let calendar = Calendar.current
        let timeframe: Timeframe = self.selectedTimeframe
        // Filter records based on whether the start or end time is within the timeframe's range.
        let timelyRecords = self.filteredRecords.filter { record in
            timeframe.range.contains(record.startTime) || timeframe.range.contains(record.endTime)
        }
        // Determine the grouping based on the timeframe.
        let grouping: (Date) -> Date = { date in
            switch timeframe {
                case .today:
                    // Group by hour.
                    return calendar.dateInterval(of: .hour, for: date)!.start
                case .thisWeek, .thisMonth:
                    // Group by day.
                    return calendar.startOfDay(for: date)
                case .thisYear:
                    // Group by month.
                    let components = calendar.dateComponents([.year, .month], from: date)
                    return calendar.date(from: components)!
                case .allTime:
                    // Group by year.
                    let components = calendar.dateComponents([.year], from: date)
                    return calendar.date(from: components)!
            }
        }
        // Group records based on the computed grouping date from the record's startTime.
        let groupedRecords = Dictionary(grouping: timelyRecords) { record in
            grouping(record.startTime)
        }
        // Prepare a date formatter for generating a description.
        let formatter = DateFormatter()
        // Set the date format based on the timeframe.
        switch timeframe {
            case .today:
                // e.g., "2 PM"
                formatter.dateFormat = "ha"
            case .thisWeek, .thisMonth:
                // e.g., "May 21"
                formatter.dateFormat = "MMM d"
            case .thisYear:
                // e.g., "May", "June"
                formatter.dateFormat = "MMMM"
            case .allTime:
                // e.g., "2025"
                formatter.dateFormat = "yyyy"
        }
        // Map each group to a single IntervalUse object.
        let usageData = groupedRecords.map { (groupDate, records) -> [IntervalUse] in
            let requests = records.count
            let inputTokens = records.reduce(0) { $0 + $1.inputTokens }
            let outputTokens = records.reduce(0) { $0 + $1.outputTokens }
            let description = formatter.string(from: groupDate)
            return [
                IntervalUse(
                    date: groupDate,
                    description: description,
                    uses: requests,
                    tokens: inputTokens,
                    type: .input
                ),
                IntervalUse(
                    date: groupDate,
                    description: description,
                    uses: requests,
                    tokens: outputTokens,
                    type: .output
                )
            ]
        }
        // Return the IntervalUse objects sorted by date in ascending order.
        return usageData
            .flatMap({ $0 })
            .sorted { data0, data1 in
                let calendar: Calendar = .current
                let data0Value: Int = calendar.component(
                    timeframe.calendarComponent,
                    from: data0.date
                )
                let data1Value: Int = calendar.component(
                    timeframe.calendarComponent,
                    from: data1.date
                )
                return data0Value < data1Value
            }
    }
    
    public var modelUsage: [ModelUse] {
        let modelUses: [
            (totalTokens: Int, uses: [ModelUse])
        ] = self.models.map { model in
            let records: [InferenceRecord] = self.filteredRecords.filter { record in
                return record.name == model
            }
            let totalInputTokens: Int = records.map(keyPath: \.inputTokens).reduce(0, +)
            let totalOutputTokens: Int = records.map(keyPath: \.outputTokens).reduce(0, +)
            return (
                totalInputTokens + totalOutputTokens,
                [
                    ModelUse(
                        model: model,
                        tokens: totalInputTokens,
                        type: .input
                    ),
                    ModelUse(
                        model: model,
                        tokens: totalOutputTokens,
                        type: .output
                    )
                ]
            )
        }
        return modelUses
            .sorted(by: \.totalTokens)
            .flatMap({ $0.uses })
            .filter({ $0.tokens > 0 })
    }
    
    /// An array of `String` containing all models used
    public var models: [String] {
        return Set(self.records.map(\.name)).sorted()
    }
    
    /// Function to save records to disk
    public func save() {
        do {
            // Save data
            let rawData: Data = try JSONEncoder().encode(
                self.records
            )
            try rawData.write(
                to: self.datastoreUrl,
                options: .atomic
            )
        } catch {
            os_log("error = %@", error.localizedDescription)
        }
    }
    
    /// Function to load records from disk
    public func load() {
        do {
            // Load data
            let rawData: Data = try Data(
                contentsOf: self.datastoreUrl
            )
            let decoder: JSONDecoder = JSONDecoder()
            self.records = try decoder.decode(
                [InferenceRecord].self,
                from: rawData
            )
        } catch {
            // Indicate error
            print("Failed to load records: \(error)")
            // Make new datastore
            self.newDatastore()
        }
    }
    
    /// Function to delete a record
    public func delete(
        _ record: Binding<InferenceRecord>
    ) {
        withAnimation(.spring()) {
            self.records = self.records.filter {
                $0.id != record.wrappedValue.id
            }
        }
    }
    
    /// Function to delete a record
    public func delete(
        _ record: InferenceRecord
    ) {
        withAnimation(.spring()) {
            self.records = self.records.filter {
                $0.id != record.id
            }
        }
    }
    
    /// Function to add a record
    @MainActor
    public func add(
        _ record: InferenceRecord
    ) {
        // Add to records
        withAnimation(.linear) {
            self.records.append(record)
            self.records.sort(by: { $0.startTime > $1.startTime })
        }
    }
    
    /// Function to make new datastore
    public func newDatastore() {
        // Setup directory
        self.patchFileIntegrity()
        self.records = []
        self.save()
    }
    
    /// Function to patch file integrity
    public func patchFileIntegrity() {
        // Setup directory if needed
        if !self.datastoreDirExists {
            try! FileManager.default.createDirectory(
                at: datastoreDirUrl,
                withIntermediateDirectories: true
            )
        }
    }
    
    /// Computed property returning the datastore's directory's url
    public var datastoreDirUrl: URL {
        return Settings.containerUrl.appendingPathComponent(
            "Inference Records"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private var datastoreDirExists: Bool {
        return self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public var datastoreUrl: URL {
        return self.datastoreDirUrl.appendingPathComponent(
            "records.json"
        )
    }
    
    /// Computed property returning if datastore exists
    private var datastoreExists: Bool {
        return self.datastoreUrl.fileExists
    }
    
    public enum Timeframe: CaseIterable {
        
        case today
        case thisWeek
        case thisMonth
        case thisYear
        case allTime
        
        var description: String {
            switch self {
                case .today:
                    return String(localized: "Today")
                case .thisWeek:
                    return String(localized: "This Week")
                case .thisMonth:
                    return String(localized: "This Month")
                case .thisYear:
                    return String(localized: "This Year")
                case .allTime:
                    return String(localized: "All Time")
            }
        }
        
        var calendarComponent: Calendar.Component {
            switch self {
                case .today:
                    return .hour
                case .thisWeek, .thisMonth:
                    return .day
                case .thisYear:
                    return .month
                case .allTime:
                    return .year
            }
        }
        
        private var startDate: Date {
            switch self {
                case .today:
                    return Date.now.oneDayAgo
                case .thisWeek:
                    return Date.now.oneWeekAgo
                case .thisMonth:
                    return Date.now.oneMonthAgo
                case .thisYear:
                    return Date.now.oneMonthAgo
                case .allTime:
                    return Date.distantPast
            }
        }
        
        var range: ClosedRange<Date> {
            return self.startDate...Date.now
        }
        
    }
    
    public struct IntervalUse: Identifiable {
        
        public var id: String {
            return self.date.ISO8601Format()
        }
        
        public var date: Date
        public var description: String
        
        public var uses: Int
        
        public var tokens: Int
        public var type: TokenType
        
    }
    
    public struct ModelUse: Identifiable {
        
        public var id: String {
            return self.model
        }
        
        public var model: String
        
        public var tokens: Int
        public var type: TokenType
        
    }
    
    public enum TokenType: String, CaseIterable, Plottable {
        case input, output
    }
    
}
