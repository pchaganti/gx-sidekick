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
