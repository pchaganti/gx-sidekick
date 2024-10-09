//
//  User.swift
//  Sidekick
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import SwiftUI

public enum Sender: String, Codable {
	
	case user
	case bot
	
	/// Computed property for the sender's icon
	var icon: some View {
		Image(systemName: self == .user ? "person.fill" : "cpu.fill")
			.font(.system(size: 17))
			.shadow(
				color: .secondary.opacity(0.3),
				radius: 2, x: 0, y: 0.5
			)
			.padding(5)
			.background(
				Circle()
					.fill(self == .user ? Color.purple : Color.green)
			)
	}
	
}
