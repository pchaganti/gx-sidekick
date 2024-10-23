//
//  Tips.swift
//  Sidekick
//
//  Created by Bean John on 10/23/24.
//

import Foundation
import TipKit

struct CreateProfilesTip: Tip {
	
	var title: Text {
		Text("Create a Profile")
	}
	
	var message: Text? {
		Text("Create profiles that **customise** chatbot behaviour, making it **reply with context from your files**.")
	}
	
	var image: Image? {
		Image(systemName: "person.fill")
	}
	
	var actions: [Action] {
		[
			Action(
				id: "view",
				title: String(localized: "View Profiles")
			)
		]
	}
	
}

struct LengthyTasksProgressTip: Tip {
	
	// Track whether there is a lengthy task
	@Parameter
	static var hasLengthyTask: Bool = false
	
	var title: Text {
		Text("View Progress")
	}
	
	var message: Text? {
		Text("Check progress of lengthy tasks, like updating your profile with new resources.")
	}
	
	var rules: [Rule] {
		[
			#Rule(Self.$hasLengthyTask) {
				$0 == true
			}
		]
	}
	
}

struct DictationTip: Tip {
	
	// Track whether the user is ready for dictation
	@Parameter
	static var readyForDictation: Bool = false
	
	var title: Text {
		Text("Use Dictation")
	}
	
	var message: Text? {
		Text("Use dictation to instruct your chatbot, hands free.")
	}
	
	var image: Image? {
		Image(systemName: "microphone.fill")
	}
	
	var rules: [Rule] {
		[
			#Rule(Self.$readyForDictation) {
				$0 == true
			}
		]
	}
	
}

struct ViewReferenceTip: Tip {
	
	// Track whether a reference was displayed
	@Parameter
	static var hasReference: Bool = false
	
	var title: Text {
		Text("View Reference")
	}
	
	var message: Text? {
		Text("Click to view a resource referenced in the chatbot's response.")
	}
	
	var rules: [Rule] {
		[
			#Rule(Self.$hasReference) {
				$0 == true
			}
		]
	}
	
}
