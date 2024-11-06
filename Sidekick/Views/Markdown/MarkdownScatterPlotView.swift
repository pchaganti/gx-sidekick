//
//  MarkdownScatterChartView.swift
//  Sidekick
//
//  Created by Bean John on 11/6/24.
//

import Charts
import SwiftUI

struct MarkdownScatterPlotView: View {
	
	@EnvironmentObject private var controller: MarkdownDataViewController
	
	@State private var flipAxis: Bool = false
	@State private var selectedPoint: Point? = nil
	
	var xIndex: Int {
		return flipAxis ? 1 : 2
	}
	var yIndex: Int {
		return flipAxis ? 2 : 1
	}
	
	var xAxisLabel: String {
		return controller.headers[xIndex]
	}
	
	var yAxisLabel: String {
		return controller.headers[yIndex]
	}
	
	private var points: [Self.Point] {
		return controller.rows.enumerated().map { index, row in
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
				index: index,
				x: x,
				y: y,
				label: row[0]
			)
		}
	}
	
	var body: some View {
		VStack {
			chart
			Divider()
			toggle
		}
		.frame(maxWidth: 350)
		.padding(5)
	}
	
	var toggle: some View {
		Button {
			withAnimation(.linear) {
				flipAxis.toggle()
			}
		} label: {
			Text("Flip Axes")
		}
		.buttonStyle(.plain)
	}
	
	
	var chart: some View {
		Chart(points) { point in
			PointMark(
				x: .value(xAxisLabel, point.x),
				y: .value(yAxisLabel, point.y)
			)
			.foregroundStyle(
				by: .value(point.label, point.label)
			)
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
		.onChange(of: selectedPoint) {
			if let selectedPoint = selectedPoint {
				print("label: \(selectedPoint.label)")
			}
		}
	}
	
	private struct Point: Identifiable, Equatable {
		
		let id: UUID = UUID()
		
		let index: Int
		
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
