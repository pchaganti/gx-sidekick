//
//  ExportButton.swift
//  Sidekick
//
//  Created by Bean John on 11/5/24.
//

import FSKit_macOS
import SwiftUI

struct ExportButton: View {
	
	@State private var isPresented: Bool = false
	
	var text: String
	var language: String?
	
	let iconName: String = {
		if #available(macOS 15, *) {
			return "document.badge.plus.fill"
		}
		return "doc.fill.badge.plus"
	}()
	
    var body: some View {
		Button {
			isPresented.toggle()
		} label: {
			Image(systemName: iconName)
				.padding(.vertical, 2)
		}
		.frame(alignment: .center)
		.sheet(isPresented: $isPresented) {
			ConfirmationSheet(
				isPresented: $isPresented,
				text: text,
				language: language
			)
			.frame(idealWidth: 400)
		}
    }
	
	struct ConfirmationSheet: View {
		
		@Binding var isPresented: Bool
		
		@State private var fileName: String = ""
		@State private var fileExtension: String = ""
		
		var text: String
		var language: String?
		
		var canSave: Bool {
			return !fileName.isEmpty && !fileExtension.isEmpty
		}
		
		var body: some View {
			VStack(
				alignment: .leading
			) {
				HStack {
					Text("Filename:")
					TextField("", text: $fileName)
				}
				HStack {
					Text("File Extension:")
					TextField("", text: $fileExtension)
				}
				Divider()
				controls
			}
			.padding()
			.onAppear {
				if let fileExtension = ProgrammingLanguage.getExtension(
					for: language ?? "nil"
				) {
					self.fileExtension = fileExtension
				}
			}
		}
		
		var controls: some View {
			HStack {
				Spacer()
				Button {
					isPresented.toggle()
				} label: {
					Text("Cancel")
				}
				Button {
					saveCode()
					isPresented.toggle()
				} label: {
					Text("Save")
				}
				.disabled(!canSave)
				.keyboardShortcut(.defaultAction)
			}
		}
		
		/// Function to save the code to a file
		private func saveCode() {
			// Select a directory
			guard let directory: URL = try? FileManager.selectFile(
				dialogTitle: String(localized: "Select a Folder"),
				canSelectFiles: false,
				canSelectDirectories: true,
				persistPermissions: true
			).first else {
				return
			}
			// Write to file
			let fileUrl: URL = directory.appendingPathComponent(
				"\(fileName).\(fileExtension)"
			)
			do {
				try text.write(to: fileUrl, atomically: true, encoding: .utf8)
			} catch {
				print("error: \(error)")
			}
		}
		
	}
	
}

extension ExportButton.ConfirmationSheet {
	
	struct ProgrammingLanguage {
		
		/// Name of the programming language, in type `String`
		var name: String
		/// File extension of the program files, in type `String`
		var fileExtension: String
		
		static let languages: [ProgrammingLanguage] = [
			.init(name: "Swift", fileExtension: "swift"),
			.init(name: "Java", fileExtension: "java"),
			.init(name: "Python", fileExtension: "py"),
			.init(name: "C++", fileExtension: "cpp"),
			.init(name: "Cplusplus", fileExtension: "cpp"),
			.init(name: "C", fileExtension: "c"),
			.init(name: "JavaScript", fileExtension: "js"),
			.init(name: "Ruby", fileExtension: "rb"),
			.init(name: "PHP", fileExtension: "php"),
			.init(name: "Kotlin", fileExtension: "kt"),
			.init(name: "Go", fileExtension: "go"),
			.init(name: "Dart", fileExtension: "dart"),
			.init(name: "Shell", fileExtension: "sh"),
			.init(name: "Bash", fileExtension: "bash"),
			.init(name: "Perl", fileExtension: "pl"),
			.init(name: "R", fileExtension: "r"),
			.init(name: "SQL", fileExtension: "sql"),
			.init(name: "HTML", fileExtension: "html"),
			.init(name: "CSS", fileExtension: "css"),
			.init(name: "TypeScript", fileExtension: "ts"),
			.init(name: "Objective-C", fileExtension: "m"),
			.init(name: "Assembly", fileExtension: "asm")
		]
		
		/// Function to get the file extension of a language
		static func getExtension(for name: String) -> String? {
			return languages
				.filter { language in
					language.name.lowercased() == name.lowercased()
				}
				.first?
				.fileExtension
		}
	}
	
}
