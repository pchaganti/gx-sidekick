//
//  MarkdownBarChartView.swift
//  Sidekick
//
//  Created by Bean John on 11/6/24.
//

import Charts
import SwiftUI

struct MarkdownBarChartView: View {
	
	@EnvironmentObject private var controller: MarkdownDataViewController
	
	private var bars: [Bar] {
		return controller.rows.enumerated().map { index, row in
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
			return Bar(
				index: index,
				value: value,
				label: row.first!
			)
		}
	}
	
    var body: some View {
		Chart(bars) { bar in
			BarMark(
				x: .value(
					controller.headers.first!,
					bar.label
				),
				y: .value(
					controller.headers.last!,
					bar.value
				)
			)
			.foregroundStyle(
				by: .value(bar.label, bar.label)
			)
			.annotation(
				position: .top,
				alignment: .center
			) {
				Text(bar.valueDescription)
					.foregroundStyle(.secondary)
			}
		}
		.aspectRatio(1.0, contentMode: .fit)
		.chartLegend(.hidden)
		.chartYAxis {
			AxisMarks(position: .leading)
		}
		.chartXAxisLabel(
			controller.headers.first!,
			position: .bottom,
			alignment: .center
		)
		.chartYAxisLabel(
			controller.headers.last!,
			position: .leading,
			alignment: .center
		)
		.frame(maxWidth: 350)
		.padding(.bottom, 5)
    }
	
	private struct Bar: Identifiable {
		
		let id: UUID = UUID()
		
		let index: Int
		let value: Double
		var valueDescription: String {
			if value.rounded() == value {
				return String(Int(value))
			}
			return String(format: "%.2f", value)
		}
		
		let label: String
	}
	
}
