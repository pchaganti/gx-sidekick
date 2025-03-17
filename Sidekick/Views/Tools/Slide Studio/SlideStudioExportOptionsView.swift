//
//  SlideStudioExportOptionsView.swift
//  Sidekick
//
//  Created by John Bean on 3/1/25.
//

import FSKit_macOS
import SwiftUI

struct SlideStudioExportOptionsView: View {
	
	@Binding var isPresented: Bool
	
	@State private var config: SlideStudioViewController.SlideExportConfiguration = .default
	
	@EnvironmentObject private var slideStudioViewController: SlideStudioViewController
	
	@State private var timer: Timer? = nil
	@State private var isExporting: Bool = false
	
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
				format
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
				Text("The name of the exported slideshow")
					.font(.caption)
			}
			Spacer()
			TextField("", text: $config.name)
				.textFieldStyle(.plain)
				.disabled(isExporting)
		}
		.padding(.horizontal, 5)
	}
	
	var format: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Format")
					.font(.title3)
					.bold()
				Text("The file format of the exported slideshow")
					.font(.caption)
			}
			Spacer()
			Picker("", selection: $config.format) {
				ForEach(
					SlideStudioViewController.SlideExportConfiguration.Format.allCases,
					id: \.self
				) { format in
					Text(format.displayName)
				}
			}
			.disabled(isExporting)
			.onChange(of: self.config.format) {
				self.checkFormat()
			}
		}
		.padding(.horizontal, 5)
	}
	
	var outputDir: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("Output Folder")
					.font(.title3)
					.bold()
				Text("Your slides will be saved to this folder")
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
			// Start export
			withAnimation(.linear) {
				self.isExporting = true
			}
			// Check output url
			if self.config.outputUrl.fileExists {
				if !self.shouldOverwrite() {
					return
				} else {
					FileManager.removeItem(at: self.config.outputUrl)
				}
			}
			// Export
			self.slideStudioViewController.exportSlides(
				config: self.config
			)
			// Set to dismiss
			self.dismissAfterExport()
		} label: {
			Text(self.exportingButtonDescription)
		}
		.keyboardShortcut(.defaultAction)
		.disabled(!self.config.isValid || self.isExporting)
	}
	
	/// Function to check export format
	private func checkFormat() {
		// If invalid config selected, show alert
		if self.config.format == .pptxEditable
			&& !self.config.format.isAvailable {
			return Dialogs.showAlert(
				title: String(localized: "Error"),
				message: String(localized: "In order to export to an editable PowerPoint, you must first install LibreOffice.")
			)
		}
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
			self.config.outputDirUrl = directoryUrl
		}
	}
	
	/// Function to check output directory
	private func shouldOverwrite() -> Bool {
		// If file already exists
		if self.config.outputUrl.fileExists {
			// Get confirmation
			return Dialogs.dichotomy(
				title: String(localized: "Warning"),
				message: String(localized: "A file with the same name already exists. Do you want to overwrite it?"),
				option1: String(localized: "Yes"),
				option2: String(localized: "No"),
				ifOption1: {},
				ifOption2: {}
			)
		}
		return false
	}
	
	/// Function to dismiss when export is complete
	private func dismissAfterExport() {
		// Save output url
		let outputUrl: URL = self.config.outputUrl
		// Set timer
		self.timer = Timer.scheduledTimer(
			withTimeInterval: 1.0,
			repeats: true
		) { _ in
			// Check if export is complete
			if outputUrl.fileExists {
				self.finishExport()
			}
		}
	}
	
	/// Function to finish export
	private func finishExport() {
		// Invalidate timer
		self.timer?.invalidate()
		self.timer = nil
		// Exit
		withAnimation(.linear) {
			self.isExporting = false
			self.isPresented = false
		}
	}
	
}
