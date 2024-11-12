//
//  SidekickTests.swift
//  SidekickTests
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import Testing
@testable import Sidekick

struct SidekickTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
	
	/// Test to check model reccomendations on different hardware
	@Test func checkModelReccomendations() async throws {
		DefaultModels.checkModelRecommendations()
	}

}
