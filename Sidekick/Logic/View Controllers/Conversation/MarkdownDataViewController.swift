//
//  MarkdownDataViewController.swift
//  Sidekick
//
//  Created by Bean John on 11/6/24.
//

import Foundation
import MarkdownUI
import SwiftUI

public class MarkdownDataViewController: ObservableObject {
    
    init(
        configuration: BlockConfiguration
    ) {
        self.configuration = configuration
        self.content = configuration.content
        // Get data
        let string: String = configuration.content.renderMarkdown()
        let rawData: [[String]]? = Self.parseMarkdownTable(string)
        self.data =  rawData
        // Get rows
        if let rawData, (rawData.count > 1) {
            var rows: [[String]] = Array(rawData.dropFirst())
            // Drop header indicator
            if rows.first!.allSatisfy({ $0 == "---" }) {
                rows = Array(rows.dropFirst())
            }
            self.rows = rows
        } else {
            self.rows = []
        }
        // Cache expensive computations
        self._cachedHeaders = Self.computeHeaders(from: rawData)
        self._cachedColumns = Self.computeColumns(from: self.rows)
        self._cachedIsNumeric = Self.computeIsNumeric(from: rawData)
        self._cachedDataFormat = Self.computeDataFormat(isNumeric: self._cachedIsNumeric)
    }
    
    @Published var selectedVisualization: Visualization = .table
    @Published var flipAxis: Bool = false
    
    /// The configuration for this "block" of Markdown
    var configuration: BlockConfiguration
    
    /// The Markdown markdown content displayed
    var content: MarkdownContent
    
    /// The data held in the table, in type `[[String]]?`
    public var data: [[String]]?
    
    // Cached properties for performance
    private let _cachedHeaders: [String]
    private let _cachedColumns: [[String]]
    private let _cachedIsNumeric: [Bool]
    private let _cachedDataFormat: DataFormat
    
    /// The data's headers (cached)
    public var headers: [String] {
        return _cachedHeaders
    }
    
    /// The data's data in rows
    public var rows: [[String]]
    
    /// The data's data in columns (cached)
    public var columns: [[String]] {
        return _cachedColumns
    }
    
    /// Returns an array of `Bool`, where each item represents whether a column is numeric (cached)
    public var isNumeric: [Bool] {
        return _cachedIsNumeric
    }
    
    // MARK: - Static computation methods for caching
    
    private static func computeHeaders(from data: [[String]]?) -> [String] {
        return (data?.first ?? []).map { value in
            return value.trim(
                prefix: "**",
                suffix: "**"
            )
        }
    }
    
    private static func computeColumns(from rows: [[String]]) -> [[String]] {
        return rows.transpose.map { row in
            return row.map { cell in
                return cell.trim(
                    prefix: "**",
                    suffix: "**"
                )
            }
        }
    }
    
    private static func computeIsNumeric(from data: [[String]]?) -> [Bool] {
        // Return if no data
        guard let data = data else { return [] }
        // Extract rows
        var dataRows: [[String]] = Array(data.dropFirst())
        // Return if no data
        if dataRows.isEmpty { return [] }
        // Remove header indicator if needed
        if dataRows.first!.allSatisfy({ $0 == "---" }) {
            dataRows = Array(dataRows.dropFirst())
        }
        // Group by column
        var dataColumns: [[String]] = dataRows.transpose
        // Convert percents to doubles
        dataColumns = dataColumns.map { column in
            column.map { data in
                let string: String = data.replacingOccurrences(
                    of: ", ",
                    with: ""
                ).replacingOccurrences(
                    of: ",",
                    with: ""
                )
                let double: Double? = Double(String(string.dropLast()))
                let isPercentage: Bool = string.hasSuffix(
                    "%"
                ) && double != nil
                if isPercentage {
                    return "\(double! / 100)"
                }
                return string
            }
        }
        return dataColumns.map { column in
            column.allSatisfy { data in
                let double: Double? = Double(data)
                return double != nil
            }
        }
    }
    
    private static func computeDataFormat(isNumeric: [Bool]) -> DataFormat {
        // Check for 1 string column + 1 data column
        let oneStringOneNumeric: Bool = (
            isNumeric.first == false && isNumeric.last == true
        ) && isNumeric.count == 2
        if oneStringOneNumeric {
            return .oneStringOneNumeric
        }
        // Check for 2 numeric columns
        let twoNumeric: Bool = isNumeric.filter({
            !$0
        }).isEmpty && isNumeric.count == 2
        if twoNumeric {
            return .twoNumeric
        }
        // Check for 1 string column + 2 data columns
        let oneStringTwoNumeric: Bool = (
            isNumeric.first == false && Array(
                isNumeric.dropFirst()
            ).filter({ !$0 }).isEmpty
        ) && isNumeric.count == 3
        if oneStringTwoNumeric {
            return .oneStringTwoNumeric
        }
        // Return unsure
        return .unknown
    }
    
    /// A `Bool` representing whether the data can be visuallised
    public var canVisualize: Bool {
        let usableFormat: Bool = dataFormat != .unknown
        let hasData: Bool = !(data?.isEmpty ?? true)
        return usableFormat && hasData
    }
    
    /// A function returning the format of the data (cached)
    public var dataFormat: DataFormat {
        return _cachedDataFormat
    }
    
    /// A function returning usable visualization types
    var visualizationTypes: [Visualization] {
        return Visualization.availibleVisualizations(
            dataFormat: self.dataFormat
        )
    }
    
    /// Function to convert raw markdown to its constituent data
    /// - Parameter markdown: Raw markdown text of type `String`
    /// - Returns: Constituent data of type `[[String]]?`
    private static func parseMarkdownTable(_ markdown: String) -> [[String]]? {
        // Split the input by newline characters to get rows
        let rows = markdown.components(separatedBy: .newlines)
        
        // Ensure there's at least one row for the header and one for the divider
        guard rows.count > 1 else { return nil }
        
        // Verify that the second row is a divider with dashes
        let dividerPattern = #"^\|?(\s*-+\s*\|)+"#
        let dividerRegex = try? NSRegularExpression(pattern: dividerPattern, options: [])
        
        // Check if the second row matches the divider pattern
        let divider = rows[1]
        guard let _ = dividerRegex?.firstMatch(in: divider, options: [], range: NSRange(location: 0, length: divider.utf16.count)) else {
            return nil
        }
        
        // Parse each row into columns by splitting on `|`
        var table: [[String]] = []
        
        for row in rows where !row.trimmingCharacters(in: .whitespaces).isEmpty {
            let columns = row.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            if !columns.isEmpty {
                table.append(columns)
            }
        }
        
        return table.isEmpty ? nil : table
    }
    
}

public enum Visualization: String, CaseIterable, Identifiable {
    
    public var id: String { self.rawValue }
    
    case table
    case pieChart
    case barChart
    case scatterPlot
    case lineChart
    
    public var description: String {
        switch self {
            case .table:
                return String(localized: "Table")
            case .pieChart:
                return String(localized: "Pie Chart")
            case .barChart:
                return String(localized: "Bar Chart")
            case .scatterPlot:
                return String(localized: "Scatter Plot")
            case .lineChart:
                return String(localized: "Line Chart")
        }
    }
    
    /// A `Bool` representing if the graph's axis can be flipped
    public var canFlipAxis: Bool {
        switch self {
            case .scatterPlot:
                return true
            case .lineChart:
                return true
            default:
                return false
        }
    }
    
    /// A function to determine usable visualization for a data format
    /// - Parameter dataFormat: The data's format, in type `DataFormat`
    /// - Returns: An array of availible visualizations, in type `Visualization`
    public static func availibleVisualizations(
        dataFormat: DataFormat
    ) -> [Visualization] {
        var visualizations: [Visualization]
        switch dataFormat {
            case .oneStringOneNumeric:
                visualizations = [.barChart, .pieChart]
            case .oneStringTwoNumeric:
                visualizations = [.scatterPlot]
            case .twoNumeric:
                visualizations = [.lineChart]
            case .unknown:
                visualizations = []
        }
        return [.table] + visualizations
    }
    
}

public enum DataFormat: String, CaseIterable {
    
    case oneStringOneNumeric
    case oneStringTwoNumeric
    case twoNumeric
    case unknown
    
}
