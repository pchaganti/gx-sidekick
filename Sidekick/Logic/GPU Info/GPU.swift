//
//  GPU.swift
//  Sidekick
//
//  Created by Bean John on 11/9/24.
//

import Foundation

public struct GPU: Identifiable {
	
	public var id: String { self.name }
	
	public var name: String
	public var tflops: CGFloat
	
	public static let all: [GPU] = [
		.init(name: "M1", tflops: 2.617),
		.init(name: "M1 Pro", tflops: 5.308),
		.init(name: "M1 Max", tflops: 10.617),
		.init(name: "M1 Ultra", tflops: 21.23),
		.init(name: "M2", tflops: 3.579),
		.init(name: "M2 Pro", tflops: 6.8),
		.init(name: "M2 Max", tflops: 13.6),
		.init(name: "M2 Ultra", tflops: 27.2),
		.init(name: "M3", tflops: 4.1),
		.init(name: "M3 Pro", tflops: 7.4),
		.init(name: "M3 Max", tflops: 16.2),
		.init(name: "M4", tflops: 4.6),
		.init(name: "M4 Pro", tflops: 9.2),
		.init(name: "M4 Max", tflops: 18.4),
	].sorted(by: \.tflops)
	
}
