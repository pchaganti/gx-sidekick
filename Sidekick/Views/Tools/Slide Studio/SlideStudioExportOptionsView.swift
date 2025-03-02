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
	}
	
	var cancelButton: some View {
		Button {
			self.isPresented.toggle()
		} label: {
			Text("Cancel")
		}
	}
	
	var exportButton: some View {
		Button {
			self.slideStudioViewController.exportSlides(
				config: self.config
			)
			self.isPresented.toggle()
		} label: {
			Text("Export")
		}
		.keyboardShortcut(.defaultAction)
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
	
}
