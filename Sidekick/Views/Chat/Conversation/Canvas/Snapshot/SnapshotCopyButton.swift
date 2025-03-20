//
//  SnapshotCopyButton.swift
//  Sidekick
//
//  Created by John Bean on 3/20/25.
//

import SwiftUI

struct SnapshotCopyButton: View {
	
	var snapshot: Snapshot
	
    var body: some View {
		Menu {
			switch self.snapshot.type {
				case .text:
					copyText
				case .site:
					copySite
			}
		} label: {
			Image(systemName: "square.on.square")
				.foregroundStyle(.secondary)
				.scaleEffect(x: -1)
		}
		.menuStyle(.circle)
		.padding(0)
		.padding(.vertical, 2)
	}
	
	var copyText: some View {
		Group {
			Button {
				self.snapshot.text.copyWithFormatting()
			} label: {
				Text("Copy")
			}
			Button {
				self.snapshot.text.copy()
			} label: {
				Text(String(localized: "Copy") + " Without Formatting")
			}
		}
	}
	
	var copySite: some View {
		Group {
			Button {
				if let html = self.snapshot.site?.html {
					html.copy()
				}
			} label: {
				Text(String(localized: "Copy") + " HTML")
			}
			Button {
				if let css = self.snapshot.site?.css {
					css.copy()
				}
			} label: {
				Text(String(localized: "Copy") + " CSS")
			}
			Button {
				if let js = self.snapshot.site?.js {
					js.copy()
				}
			} label: {
				Text(String(localized: "Copy") + " JS")
			}
		}
	}
	
}
