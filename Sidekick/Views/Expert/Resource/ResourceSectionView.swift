//
//  ResourceSectionView.swift
//  Sidekick
//
//  Created by Bean John on 10/11/24.
//

import FSKit_macOS
import SwiftUI

struct ResourceSectionView: View {
	
	@Binding var expert: Expert
	
	@State private var showAddOptions: Bool = false
	@State private var isAddingWebsite: Bool = false
	@State private var isAddingEmail: Bool = false
	
	@EnvironmentObject private var lengthyTasksController: LengthyTasksController
	
    var isTutorial: Bool = false
    var fileUrl: URL? = nil
    
	var isUpdating: Bool {
		let taskName: String = String(
			localized: "Updating resource index for expert \"\(self.expert.name)\""
		)
		return lengthyTasksController.tasks
			.map(\.name)
			.contains(
				taskName
			)
	}
	
    var body: some View {
		Section {
			VStack {
				selectResources
				Divider()
				persistResources
			}
			.padding(.horizontal, 5)
		} header: {
			Text("Resources")
		}
		.confirmationDialog(
			"Resource Type",
			isPresented: $showAddOptions
		) {
			Button {
                if !isTutorial {
                    self.addFile()
                } else {
                    self.tutorialAddFile()
                }
			} label: {
				Text("File / Folder")
			}
			Button {
				self.isAddingWebsite.toggle()
			} label: {
				Text("Website")
			}
            .disabled(isTutorial)
			Button {
				self.isAddingEmail.toggle()
			} label: {
				Text("Email (Mail.app only)")
			}
            .disabled(isTutorial)
		} message: {
			Text("What type of resource do you want to add?")
		}
		.sheet(isPresented: $isAddingWebsite) {
			WebsiteSelectionView(
				expert: $expert,
				isAddingWebsite: $isAddingWebsite
			)
		}
		.sheet(isPresented: $isAddingEmail) {
			EmailSelectionView(
				expert: $expert,
				isAddingEmail: $isAddingEmail
			)
		}
    }
	
	var selectResources: some View {
		VStack(alignment: .leading) {
			HStack {
				VStack(alignment: .leading) {
					Text("Resources: \(expert.resources.resources.count)")
						.font(.title3)
						.bold()
					Text("Files, folders or websites stored in the chatbot's \"conscience\"")
						.font(.caption)
				}
				if isUpdating {
					ProgressView()
						.progressViewStyle(.circular)
						.scaleEffect(0.5)
				}
				Spacer()
				Button {
					self.showAddOptions.toggle()
				} label: {
					Text("Add")
				}
				.disabled(self.isUpdating)
				Button {
					Task { @MainActor in
						await $expert.update()
					}
				} label: {
					Text("Update")
				}
                .disabled(self.isUpdating || self.isTutorial)
			}
			Divider()
            ResourceSelectionView(expert: self.$expert)
		}
	}
	
	var persistResources: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				Text("Persist Resources")
					.font(.title3)
					.bold()
				Text("Keep resources between sessions")
					.font(.caption)
			}
			Spacer()
			Toggle("", isOn: $expert.persistResources)
				.toggleStyle(.switch)
                .disabled(isTutorial)
		}
	}
	
	@MainActor
	private func addFile() {
		guard let selectedUrls: [URL] = try? FileManager.selectFile(
			dialogTitle: String(localized: "Select Files or Folders"),
			allowMultipleSelection: true
		) else { return }
        self.addUrls(urls: selectedUrls)
	}
    
    @MainActor
    private func tutorialAddFile() {
        guard let selectedUrls: [URL] = try? FileManager.selectFile(
            rootUrl: fileUrl,
            dialogTitle: String(localized: "Select Files or Folders"),
            allowMultipleSelection: true
        ) else { return }
        // Check
        if selectedUrls != [fileUrl] {
            // Show alert and return
            Dialogs.showAlert(
                title: String(localized: "Error"),
                message: String(localized: "Wrong files selected. Please select the file \"\(fileUrl?.lastPathComponent ?? "")\".")
            )
            return
        }
        // Add
        self.addUrls(urls: selectedUrls)
    }
	
    @MainActor
    private func addUrls(urls: [URL]) {
        let resources: [Resource] = urls.map({
            Resource(url: $0)
        })
        Task { @MainActor in
            await $expert.addResources(resources)
        }
    }
    
}
