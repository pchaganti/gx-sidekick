//
//  IntroductionPage.swift
//  Sidekick
//
//  Created by Bean John on 12/17/24.
//

import Foundation
import SwiftUI

enum IntroductionPage: CaseIterable {
	
    case useExperts
    case setupExpert
    case webSearch
    case functionUse
    case inlineWritingAssistantCommands
    case inlineWritingAssistantCompletions
	case done
	
	public var content: Content? {
		switch self {
			case .useExperts:
				return Content(
					image: Image(.useExperts),
					title: String(localized: "Experts"),
					description: String(localized: "Create and use experts to allow the chatbot to reply with **domain specific** information from your own files and folders.")
				)
			case .webSearch:
				return Content(
					image: Image(.webSearch),
					title: String(localized: "Web Search"),
					description: String(localized: "Use Web Search to find up to date information about a topic.")
				)
            case .functionUse:
				return Content(
					image: Image(.functionUse),
					title: String(localized: "Functions"),
					description: String(localized: "Sidekick can call functions to obtain information from other applications and perform tasks. For example, when asked to reschedule a meeting, Sidekick can get all events from your calendar, find an available time slot, and then reschedule the meeting by creating a calendar event and drafting an email.")
				)
            case .inlineWritingAssistantCommands:
				return Content(
					image: Image(.inlineWritingAssistantCommands),
					title: String(localized: "Inline Writing Assistant Commands"),
					description: String(localized: "Press 'Command + Control + I' to access Sidekick's inline writing assistant. For example, use the 'Answer Question' command to do your homework without leaving Microsoft Word!")
				)
            case .inlineWritingAssistantCompletions:
                return Content(
                    image: Image(.inlineWritingAssistantCompletions),
                    title: String(localized: "Inline Writing Assistant Completions"),
                    description: String(localized: "Use typing completions to speed up composition. Instead of typing out a word, just press 'Tab' to complete it.")
                )
			default:
				return nil
		}
	}
	
	struct Content {
		
		var image: Image
		var title: String
		var description: String
		
	}
	
}
