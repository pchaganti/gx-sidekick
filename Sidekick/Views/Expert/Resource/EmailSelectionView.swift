//
//  EmailSelectionView.swift
//  Sidekick
//
//  Created by John Bean on 3/17/25.
//

import FSKit_macOS
import OSLog
import SwiftfulLoadingIndicators
import SwiftUI

struct EmailSelectionView: View {
	
	/// A `Logger` object for the `EmailSelectionView` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: EmailSelectionView.self)
	)
	
	@Binding var expert: Expert
	@Binding var isAddingEmail: Bool
	
	@State private var emails: [Email] = []
	@State private var selectionStep: SelectionStep = .permissions
	
	let emailDirectoryUrl: URL = URL
		.libraryDirectory
		.appendingPathComponent("Mail")
		.appendingPathComponent("V10")
	
	var body: some View {
		Group {
			switch selectionStep {
				case .permissions:
					permissionsView
				case .scanning:
					scanningView
				case .selectEmail:
					selectEmailView
			}
		}
		.padding(10)
	}
	
	var permissionsView: some View {
		VStack {
			Text("Sidekick needs permission to read your emails in Apple Mail. Please click the button below and press \"Open\".")
				.font(.title3)
			Button {
				if self.getPermission() {
					// Move to next page
					self.selectionStep.nextCase()
					Task {
						// Scan for email addresses
						await self.scanForEmails()
						// Move to next page
						Task { @MainActor in
							self.selectionStep.nextCase()
						}
					}
				}
			} label: {
				Text("Grant Permission")
			}
			.controlSize(.large)
			.keyboardShortcut(.defaultAction)
		}
	}
	
	var scanningView: some View {
		VStack(
			spacing: 35
		) {
			LoadingIndicator(
				animation: .threeBallsTriangle,
				size: .large
			)
			Text("Guessing your email addresses...")
				.font(.title3)
				.bold()
		}
		.padding(7)
	}
	
	var selectEmailView: some View {
		VStack {
			HStack {
				Text("Select an Email Address:")
					.font(.title2)
					.bold()
				Spacer()
			}
			List(self.emails) { email in
				HStack {
					Button {
						withAnimation(.linear) {
							self.selectEmail(email: email)
						}
					} label: {
						Text(email.address)
					}
					Spacer()
					Button {
						NSWorkspace.shared.open(email.url)
					} label: {
						Label("Show in Finder", systemImage: "pip.exit")
					}
					.labelStyle(.iconOnly)
				}
				.buttonStyle(.plain)
			}
			Divider()
			HStack {
				Spacer()
				Button {
					self.isAddingEmail.toggle()
				} label: {
					Text("Cancel")
				}
				.controlSize(.large)
			}
		}
		.padding(4)
		.frame(height: 450)
	}
	
	@MainActor
	private func getPermission() -> Bool {
		if let selectedUrl: URL = try? FileManager.selectFile(
			rootUrl: self.emailDirectoryUrl,
			dialogTitle: "Click \"Open\"",
			canSelectFiles: false,
			canSelectDirectories: true,
			showHiddenFiles: false
		).first, selectedUrl == self.emailDirectoryUrl {
			return true
		}
		return false
	}
	
	private func scanForEmails() async {
		do {
			// Get email folders
			let directories: [URL] = try FileManager.default.contentsOfDirectory(
				at: self.emailDirectoryUrl,
				includingPropertiesForKeys: nil,
				options: .skipsSubdirectoryDescendants
			).filter {
				$0.lastPathComponent != "MailData" && !$0.lastPathComponent.hasPrefix(".")
			}
			// Extract email from each folder
			self.emails = await directories.concurrentMap  { directory in
				if let address = await self.findAddress(in: directory) {
					return Email(address: address, url: directory)
				}
				return nil
			}.compactMap { $0 }.sorted { email0, email1 in
				email0.address < email1.address
			}
		} catch {
			Self.logger.error("\(error, privacy: .public)")
			// Display dialog
			Task { @MainActor in
				Dialogs.showAlert(
					title: "Error",
					message: error.localizedDescription
				)
				// Dismiss sheet
				isAddingEmail = false
			}
		}
	}
	
	private func findAddress(
		in url: URL
	) async -> String? {
		// Get all `.emlx` files
		let urls: [URL] = url.contents?.filter { file in
			return file.pathExtension == "emlx"
		} ?? []
		// Sample a subset
		let subsetCount: Int = 25
		let emlxUrls: [URL] = Array(Array(Set(urls)).dropFirst(max(urls.count - subsetCount, 0)))
		let emlxStrings: [String] = emlxUrls.map { url in
			return try? String(contentsOf: url, encoding: .utf8)
		}.compactMap { $0 }
		let emails: [String] = emlxStrings.flatMap { string in
			return string.extractEmailAddresses()
		}
		return emails.mode?.lowercased()
	}
	
	private func selectEmail(email: Email) {
		// Add resource
		let resources: Resource = Resource(url: email.url)
		Task { @MainActor in
			await $expert.addResource(resources)
		}
		// Dismiss sheet
		isAddingEmail = false
	}
	
	struct Email: Identifiable {
		
		var id: UUID = UUID()
		var address: String
		var url: URL
		
	}
	
	enum SelectionStep: CaseIterable {
		case permissions, scanning, selectEmail
	}
	
}
