//
//  MarkdownLineChartView.swift
//  Sidekick
//
//  Created by Bean John on 11/6/24.
//

import Charts
import SwiftUI

struct MarkdownLineChartView: View {
	
	@EnvironmentObject private var controller: MarkdownDataViewController
	
	@State private var selectedPoint: Point? = nil
	
	var xIndex: Int {
		return controller.flipAxis ? 1 : 0
	}
	var yIndex: Int {
		return controller.flipAxis ? 0 : 1
	}
	
	var xAxisLabel: String {
		return controller.headers[xIndex]
	}
	
	var yAxisLabel: String {
		return controller.headers[yIndex]
	}
	
	private var points: [Self.Point] {
		return controller.rows.map { row in
			let x: Double = {
				let str: String = row[xIndex].replacingOccurrences(
					of: ", ",
					with: ""
				).replacingOccurrences(
					of: ",",
					with: ""
				)
				return Double(str)!
			}()
			let y: Double = {
				let str: String = row[yIndex].replacingOccurrences(
					of: ", ",
					with: ""
				).replacingOccurrences(
					of: ",",
					with: ""
				)
				return Double(str)!
			}()
			return Point(
				x: x,
				y: y,
				label: row[0]
			)
		}
	}
	
	var body: some View {
		chart
			.frame(maxWidth: 350)
			.padding(5)
	}
	
	var chart: some View {
		Chart(points) { point in
			LineMark(
				x: .value(xAxisLabel, point.x),
				y: .value(yAxisLabel, point.y)
			)
			.foregroundStyle(Color.accentColor)
		}
		.aspectRatio(1.0, contentMode: .fit)
		.chartYAxis {
			AxisMarks(position: .leading)
		}
		.chartXAxisLabel(
			xAxisLabel,
			position: .bottom,
			alignment: .center
		)
		.chartYAxisLabel(
			yAxisLabel,
			position: .leading,
			alignment: .center
		)
	}
	
	private struct Point: Identifiable {
		
		let id: UUID = UUID()
		
		let x: Double
		let y: Double
		
		var description: String {
			let x: String = {
				if self.x.rounded() == self.x {
					return String(Int(self.x))
				}
				return String(format: "%.2f", self.x)
			}()
			let y: String = {
				if self.y.rounded() == self.y {
					return String(Int(self.y))
				}
				return String(format: "%.2f", self.y)
			}()
			return "(\(x), \(y))"
		}
		
		let label: String
	}
	
}
