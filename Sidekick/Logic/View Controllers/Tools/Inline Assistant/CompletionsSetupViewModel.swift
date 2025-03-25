//
//  CompletionsSetupViewModel.swift
//  Sidekick
//
//  Created by John Bean on 3/25/25.
//

import Foundation
import SwiftUI

public class CompletionsSetupViewModel: ObservableObject {
	
	@Published public var step: Step = .nextTokenTutorial
	
	public enum Step: CaseIterable {
		case nextTokenTutorial
		case allTokensTutorial
		case downloadModel
		case done
	}
	
}
