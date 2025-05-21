//
//  Extension+Date.swift
//  Sidekick
//
//  Created by John Bean on 3/2/25.
//

import Foundation

public extension Date {
	
	/// A `String` representing the current date
	var dateString: String {
		let subString: Substring = self.description
			.split(separator: " ").first ?? Substring(
				self.description
			)
		return String(subString).replacingOccurrences(of: "-", with: " ")
	}
    
    /// A `Date` representing the date one day ago
    var oneDayAgo: Date {
        return Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: self
        )!
    }
    
    /// A `Date` representing the same day of the previous week
    var oneWeekAgo: Date {
        return Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: self
        )!
    }
    
    /// A `Date` representing the same day of the previous month
    var oneMonthAgo: Date {
        return Calendar.current.date(
            byAdding: .month,
            value: -1,
            to: self
        )!
    }
    
    /// A `Date` representing the same day of the previous year
    var oneYearAgo: Date {
        return Calendar.current.date(
            byAdding: .year,
            value: -1,
            to: self
        )!
    }
	
}
