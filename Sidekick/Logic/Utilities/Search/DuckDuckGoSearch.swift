//
//  DuckDuckGoSearch.swift
//  Sidekick
//
//  Created by John Bean on 4/17/25.
//

import Foundation
import OSLog

public class DuckDuckGoSearch {
    
    /// A `Logger` object for the `DuckDuckGoSearch` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DuckDuckGoSearch.self)
    )
    
    /// Function to remove HTML tags using regex
    private static func removeHTMLTags(
        from html: String
    ) -> String {
        let pattern = "<[^>]+>"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: html.utf16.count)
        return regex?.stringByReplacingMatches(
            in: html,
            options: [],
            range: range,
            withTemplate: ""
        ) ?? html
    }
    
    /// Function to decode common HTML entities and numeric codes
    private static func decodeHTMLEntities(
        _ string: String
    ) -> String {
        var result = string
        // Replace common entities
        let entities: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&quot;": "\"",
            "&lt;": "<",
            "&gt;": ">",
            "&#39;": "'",
            "&#x27;": "'",
            "&#x2F;": "/",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\""
        ]
        for (entity, value) in entities {
            result = result.replacingOccurrences(of: entity, with: value)
        }
        // Numeric decimal entities: &#1234;
        let decimalPattern = "&#(\\d+);"
        let decimalRegex = try! NSRegularExpression(pattern: decimalPattern, options: [])
        let matches = decimalRegex.matches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count))
        for match in matches.reversed() {
            if let range = Range(match.range(at: 1), in: result),
               let code = Int(result[range]),
               let scalar = UnicodeScalar(code) {
                let char = String(scalar)
                let fullRange = match.range(at: 0)
                if let swiftRange = Range(fullRange, in: result) {
                    result.replaceSubrange(swiftRange, with: char)
                }
            }
        }
        // Numeric hex entities: &#x1F60A;
        let hexPattern = "&#x([0-9A-Fa-f]+);"
        let hexRegex = try! NSRegularExpression(pattern: hexPattern, options: [])
        let hexMatches = hexRegex.matches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count))
        for match in hexMatches.reversed() {
            if let range = Range(match.range(at: 1), in: result),
               let code = Int(result[range], radix: 16),
               let scalar = UnicodeScalar(code) {
                let char = String(scalar)
                let fullRange = match.range(at: 0)
                if let swiftRange = Range(fullRange, in: result) {
                    result.replaceSubrange(swiftRange, with: char)
                }
            }
        }
        return result
    }
    
    /// Function to search DuckDuckGo for sources
    public static func search(
        query: String,
        resultCount: Int
    ) async throws -> [Source] {
        // Formulate parameters
        let maxCount = min(max(resultCount, 1), 5)
        guard let query = query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) else {
            return []
        }
        let urlString = "https://html.duckduckgo.com/html/?q=\(query)"
        guard let url = URL(string: urlString) else { return [] }
        // Formulate request
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        // Make request
        let startTime: Date = .now
        let (data, _) = try await URLSession.shared.data(for: request)
        Self.logger.info(
            "DuckDuckGo returned results in \(Date.now.timeIntervalSince(startTime)) secs"
        )
        guard let html = String(data: data, encoding: .utf8) else { return [] }
        // Parse results
        let pattern = #"<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>.*?</a>.*?(?:<a[^>]*class="result__snippet"[^>]*>(.*?)</a>|<div[^>]*class="result__snippet"[^>]*>(.*?)</div>)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
        let nsrange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsrange)
        // Process results
        var results: [Source] = []
        for match in matches {
            guard let hrefRange = Range(match.range(at: 1), in: html) else { continue }
            let duckURLStr = String(html[hrefRange])
            guard let components = URLComponents(string: duckURLStr),
                  let uddgValue = components.queryItems?.first(where: { $0.name == "uddg" })?.value,
                  let decoded = uddgValue.removingPercentEncoding,
                  let resultURL = URL(string: decoded) else {
                continue
            }
            let snippetRange2 = match.range(at: 2)
            let snippetRange3 = match.range(at: 3)
            var snippet: String?
            if snippetRange2.location != NSNotFound, let range = Range(snippetRange2, in: html) {
                snippet = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if snippetRange3.location != NSNotFound, let range = Range(snippetRange3, in: html) {
                snippet = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard let textWithHTML = snippet, !textWithHTML.isEmpty else { continue }
            let cleanText = Self.decodeHTMLEntities(
                Self.removeHTMLTags(from: textWithHTML)
            )
            guard !cleanText.isEmpty else { continue }
            // Create source
            let source: Source = Source(
                text: cleanText,
                source: resultURL.absoluteString
            )
            results.append(source)
            // Exit if enough
            if results.count == maxCount { break }
        }
        // Return results
        return results
    }
    
}
