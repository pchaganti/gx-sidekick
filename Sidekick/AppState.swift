//
//  AppState.swift
//  Sidekick
//
//  Created by Bean John on 11/5/24.
//

import Foundation
import SwiftUI

public class AppState: ObservableObject {
	
	static let shared: AppState = AppState()
	
	@Published var commandSelectedExpertId: UUID? = nil
	
	static func setCommandSelectedExpertId(_ id: UUID) {
		Self.shared.commandSelectedExpertId = id
	}
	
}
