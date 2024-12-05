//
//  PendingMessage.swift
//  Sidekick
//
//  Created by Bean John on 11/26/24.
//

import Foundation

actor PendingMessage {
	
	init(text: String = "") {
		self.text = text
	}
	
	private var text: String = ""
	
	public func append(_ text: String) async {
		return self.text.append(text)
	}
	
}
