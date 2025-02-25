//
//  Extension+Collection.swift
//  Sidekick
//
//  Created by Bean John on 11/6/24.
//

import Foundation

extension Collection where Self.Iterator.Element: Collection {
	var transpose: Array<Array<Self.Iterator.Element.Iterator.Element>> {
		var result = Array<Array<Self.Iterator.Element.Iterator.Element>>()
		if self.isEmpty {return result}
		
		var index = self.first!.startIndex
		while index != self.first!.endIndex {
			var subresult = Array<Self.Iterator.Element.Iterator.Element>()
			for subarray in self {
				subresult.append(subarray[index])
			}
			result.append(subresult)
			index = self.first!.index(after: index)
		}
		return result
	}
}

extension Array where Element == Double {
	
	/// Calculates the standard deviation of array elements
	func standardDeviation() -> Double? {
		guard count > 0 else { return nil }
		let mean = reduce(0.0, +) / Double(count)
		let variance = map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(count)
		return sqrt(variance)
	}
	
	/// Calculates the variance of array elements
	func variance() -> Double? {
		guard count > 0 else { return nil }
		let mean = reduce(0.0, +) / Double(count)
		let variance = map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(count)
		return variance
	}
	
}
