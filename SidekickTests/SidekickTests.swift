//
//  SidekickTests.swift
//  SidekickTests
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import Testing
import DefaultModels
@testable import Sidekick

struct SidekickTests {
	
	/// Test to check model reccomendations on different hardware
	@Test func checkModelReccomendations() async throws {
		await DefaultModels.checkModelRecommendations()
	}

}
