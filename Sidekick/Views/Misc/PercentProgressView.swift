//
//  PercentProgressView.swift
//  Sidekick
//
//  Created by Bean John on 11/12/24.
//

import SwiftUI

struct PercentProgressView: View {
    
    let progress: Double
    
    private var percentage: Int {
        Int((progress * 100).rounded())
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color.gray.opacity(0.3),
                    lineWidth: 5
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    Color.orange,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)
            
            // Percentage text
            Text("\(percentage)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
}
