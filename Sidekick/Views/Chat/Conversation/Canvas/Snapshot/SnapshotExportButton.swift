//
//  SnapshotExportButton.swift
//  Sidekick
//
//  Created by John Bean on 3/20/25.
//

import FSKit_macOS
import SwiftUI

struct SnapshotExportButton: View {
	
	var snapshot: Snapshot
	
	@State private var isExportingText: Bool = false
	@State private var isExportingSite: Bool = false
	
    var body: some View {
		Button {
			switch self.snapshot.type {
				case .text:
					self.isExportingText = true
				case .site:
					self.isExportingSite = true
			}
		} label: {
			Image(systemName: "square.and.arrow.up")
				.foregroundStyle(.secondary)
				.padding(.bottom, 2)
		}
		.buttonStyle(.plain)
		.keyboardShortcut("s", modifiers: [.command])
		.sheet(isPresented: $isExportingText) {
			TextExportView(
				isPresented: self.$isExportingText,
				snapshot: snapshot
			)
		}
		.sheet(isPresented: $isExportingSite) {
			SiteExportView(
				isPresented: self.$isExportingSite,
				snapshot: snapshot
			)
		}
    }
	
	struct TextExportView: View {
		
		@Binding var isPresented: Bool
		
		@State private var filename: String = "file \(Date.now.dateString)"
		@State private var `extension`: String = "md"
		@State private var outputDirUrl: URL = URL.downloadsDirectory
		@State private var isExporting: Bool = false
		
		var snapshot: Snapshot
		
		private var canExport: Bool {
			return !self.filename.isEmpty && !self.extension.isEmpty
		}
		
		private var exportingButtonDescription: String {
			return self.isExporting ? String(localized: "Exporting...") : String(localized: "Export")
		}
		
		var body: some View {
			VStack {
				form
				Divider()
				HStack {
					Spacer()
					cancelButton
					exportButton
				}
				.controlSize(.large)
				.padding([.bottom, .trailing], 15)
			}
		}
		
		var form: some View {
			Form {
				Section {
					name
					outputDir
				} header: {
					Text("Export Options")
				}
			}
			.formStyle(.grouped)
		}
		
		var name: some View {
			HStack {
				VStack(alignment: .leading) {
					Text("Filename")
						.font(.title3)
						.bold()
					Text("The filename of the exported file")
						.font(.caption)
				}
				Spacer()
				HStack(
					alignment: .bottom,
					spacing: 2
				) {
					TextField("", text: self.$filename)
						.frame(maxWidth: 100)
					Text(".")
						.bold()
					TextField("", text: self.$extension)
						.frame(maxWidth: 30)
				}
				.focusable(false)
				.textFieldStyle(.roundedBorder)
				.disabled(isExporting)
				.padding(.bottom)
			}
			.padding(.horizontal, 5)
		}
		
		var outputDir: some View {
			HStack {
				VStack(alignment: .leading) {
					Text("Output Folder")
						.font(.title3)
						.bold()
					Text("Your file will be saved to this folder")
						.font(.caption)
				}
				Spacer()
				Button {
					self.selectOutputDirectory()
				} label: {
					Text("Select")
				}
			}
			.padding(.horizontal, 5)
			.disabled(isExporting)
		}
		
		var cancelButton: some View {
			Button {
				self.isPresented.toggle()
			} label: {
				Text("Cancel")
			}
			.disabled(isExporting)
		}
		
		var exportButton: some View {
			Button {
				self.exportText()
			} label: {
				Text(self.exportingButtonDescription)
			}
			.keyboardShortcut(.defaultAction)
			.disabled(!self.canExport || self.isExporting)
		}
		
		/// Function to select output directory
		private func selectOutputDirectory() {
			// Select a directory
			if let directoryUrl: URL = try? FileManager.selectFile(
				rootUrl: .downloadsDirectory,
				dialogTitle: String(localized: "Select a Folder"),
				canSelectFiles: false
			).first {
				// Set the output directory
				self.outputDirUrl = directoryUrl
			}
		}
		
		/// Function to export the text
		private func exportText() {
			do {
				// Try to export
				let fileUrl: URL = self.outputDirUrl.appendingPathComponent(
					"\(self.filename).\(self.extension)"
				)
				try self.snapshot.text.write(
					to: fileUrl,
					atomically: true,
					encoding: .utf8
				)
			} catch {
				Dialogs.showAlert(
					title: String(localized: "Error"),
					message: error.localizedDescription
				)
			}
			// Close sheet
			self.isPresented = false
		}
		
	}
	
	struct SiteExportView: View {
		
		@Binding var isPresented: Bool
		
		@State private var dirName: String = "site \(Date.now.dateString)"
		@State private var outputDirUrl: URL = URL.downloadsDirectory
		@State private var isExporting: Bool = false
		
		var snapshot: Snapshot
		
		private var canExport: Bool {
			return !self.dirName.isEmpty
		}
		
		private var exportingButtonDescription: String {
			return self.isExporting ? String(localized: "Exporting...") : String(localized: "Export")
		}
		
		var body: some View {
			VStack {
				form
				Divider()
				HStack {
					Spacer()
					cancelButton
					exportButton
				}
				.controlSize(.large)
				.padding([.bottom, .trailing], 15)
			}
		}
		
		var form: some View {
			Form {
				Section {
					name
					outputDir
				} header: {
					Text("Export Options")
				}
			}
			.formStyle(.grouped)
		}
		
		var name: some View {
			HStack {
				VStack(alignment: .leading) {
					Text("Name")
						.font(.title3)
						.bold()
					Text("The name of the folder containing the site")
						.font(.caption)
				}
				Spacer()
				TextField("", text: self.$dirName)
					.textFieldStyle(.plain)
					.disabled(isExporting)
			}
			.padding(.horizontal, 5)
		}
		
		var outputDir: some View {
			HStack {
				VStack(alignment: .leading) {
					Text("Output Folder")
						.font(.title3)
						.bold()
					Text("Your site will be saved to this folder")
						.font(.caption)
				}
				Spacer()
				Button {
					self.selectOutputDirectory()
				} label: {
					Text("Select")
				}
			}
			.padding(.horizontal, 5)
			.disabled(isExporting)
		}
		
		var cancelButton: some View {
			Button {
				self.isPresented.toggle()
			} label: {
				Text("Cancel")
			}
			.disabled(isExporting)
		}
		
		var exportButton: some View {
			Button {
				self.exportSite()
			} label: {
				Text(self.exportingButtonDescription)
			}
			.keyboardShortcut(.defaultAction)
			.disabled(!self.canExport || self.isExporting)
		}
		
		/// Function to select output directory
		private func selectOutputDirectory() {
			// Select a directory
			if let directoryUrl: URL = try? FileManager.selectFile(
				rootUrl: .downloadsDirectory,
				dialogTitle: String(localized: "Select a Folder"),
				canSelectFiles: false
			).first {
				// Set the output directory
				self.outputDirUrl = directoryUrl
			}
		}
		
		/// Function to export the site
		private func exportSite() {
			do {
				// Try to export
				try self.snapshot.site?.export(
					name: self.dirName,
					outputDirUrl: self.outputDirUrl
				)
			} catch {
				Dialogs.showAlert(
					title: String(localized: "Error"),
					message: error.localizedDescription
				)
			}
			// Close sheet
			self.isPresented = false
		}
		
	}
	
}
