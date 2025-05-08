//
//  ScrollMask.swift
//  Sidekick
//
//  Created by Bean John on 10/24/24.
//

import SwiftUI

struct ScrollMask: View {
	
    let edge: Edge
	
    var startPoint: UnitPoint {
        switch edge {
            case .top:
                return UnitPoint(x: 0.5, y: 0)
            case .bottom:
                return UnitPoint(x: 0.5, y: 1)
            case .leading:
                return UnitPoint(x: 0, y: 0.5)
            case .trailing:
                return UnitPoint(x: 1, y: 0.5)
        }
    }
    
    var endPoint: UnitPoint {
        switch edge {
            case .top:
                return UnitPoint(x: 0.5, y: 1)
            case .bottom:
                return UnitPoint(x: 0.5, y: 0)
            case .leading:
                return UnitPoint(x: 1, y: 0.5)
            case .trailing:
                return UnitPoint(x: 0, y: 0.5)
        }
    }
    
	var body: some View {
		LinearGradient(
			colors: [.black, .clear],
            startPoint: self.startPoint,
            endPoint: self.endPoint
		)
        .if(self.edge.isHorizontal) { view in
            view
                .frame(width: 50)
                .frame(maxHeight: .infinity)
        }
        .if(self.edge.isVertical) { view in
            view
                .frame(height: 50)
                .frame(maxWidth: .infinity)
        }
		.blendMode(.destinationOut)
	}
	
    enum Edge {
        
        case top, bottom, leading, trailing
        
        var isVertical: Bool { [.top, .bottom].contains(self) }
        var isHorizontal: Bool { !isVertical }
        
    }
    
}
