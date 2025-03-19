//
//  MarkdownPieChartView.swift
//  Sidekick
//
//  Created by Bean John on 11/6/24.
//

import Charts
import SwiftUI

struct MarkdownPieChartView: View {
	
	@EnvironmentObject private var controller: MarkdownDataViewController
	
	private var sectors: [Sector] {
		let total: Double = controller.rows.map({ row in
			let processedRow: String = row.last!.replacingOccurrences(
				of: ", ",
				with: ""
			).replacingOccurrences(
				of: ",",
				with: ""
			).dropSuffixIfPresent(
				"%"
			)
			return Double(processedRow) ?? 0
		}).compactMap({ $0 }).reduce(
			0, +
		)
		return controller.rows.map { row in
			let value: Double = Double(
				row.last!.replacingOccurrences(
					of: ", ",
					with: ""
				).replacingOccurrences(
					of: ",",
					with: ""
				).dropSuffixIfPresent(
					"%"
				)
			) ?? 0
			return Sector(
				value: value,
				total: total,
				label: row.first!
			)
		}
	}
	
    var body: some View {
		Chart(sectors) { sector in
			SectorMark(
				angle: .value(
					sector.text,
					sector.value
				),
				angularInset: 1.5
			)
			.cornerRadius(3)
			.annotation(position: .overlay) {
				Text(sector.percentage)
					.foregroundStyle(.white)
			}
			.foregroundStyle(
				by: .value(
					sector.text,
					sector.label
				)
			)
		}
		.frame(idealWidth: 300, idealHeight: 300)
		.fixedSize(horizontal: true, vertical: false)
		.padding(.bottom, 5)
    }
	
	private struct Sector: Identifiable {
		let id: UUID = UUID()
		let value: Double
		let total: Double
		var percentage: String {
			return String(format: "%.1f", (value / total) * 100) + "%"
		}
		let label: String
		var text: Text {
			Text(label)
		}
	}
	
}
