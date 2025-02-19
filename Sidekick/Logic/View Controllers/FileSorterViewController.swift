//
//  FileSorterViewController.swift
//  Sidekick
//
//  Created by Bean John on 12/3/24.
//

import SwiftUI

public class FileSorterViewController: ObservableObject {
	
	static let shared: FileSorterViewController = FileSorterViewController()
	
	@Published var filesToSort: [FileToSort] = []
	
}
