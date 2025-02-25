//
//  Extension+CaseIterable.swift
//  Sidekick
//
//  Created by John Bean on 2/23/25.
//

import Foundation
import SwiftUI

public extension CaseIterable where Self: Equatable {
	
	/// A `Bool` indicating if there is a previous case
	var hasPrev: Bool {
		return self.progress > 0
	}
	
	/// A `Bool` indicating if there is a next case
	var hasNext: Bool {
		return self.progress < (Self.allCases.count - 1)
	}
	
	/// An array indicating a sequence of cases
	var caseSequence: [Self] {
		return Array(Self.allCases) + Array(Self.allCases)
	}
	
	/// An `Int` representing the case's number
	var progress: Int {
		return self.caseSequence.firstIndex(of: self) ?? 0
	}
	
	/// A function to switch to the next case
	mutating func nextCase() {
		withAnimation(.linear) {
			self = self.caseSequence[self.progress + 1]
		}
	}
	
	/// A function to switch to the previous case
	mutating func prevCase() {
		let stepNumber: Int = self.caseSequence.lastIndex(
			of: self
		) ?? 0
		withAnimation(.linear) {
			self = self.caseSequence[stepNumber - 1]
		}
	}
	
}
