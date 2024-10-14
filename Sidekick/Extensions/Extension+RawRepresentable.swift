//
//  Extension+RawRepresentable.swift
//  Sidekick
//
//  Created by Bean John on 10/10/24.
//

import Foundation

protocol NotificationName {
	var name: Notification.Name { get }
}

extension RawRepresentable where RawValue == String, Self: NotificationName {
	var name: Notification.Name {
		get {
			return Notification.Name(self.rawValue)
		}
	}
}
