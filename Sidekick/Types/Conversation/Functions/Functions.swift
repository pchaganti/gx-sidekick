//
//  Functions.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation

enum Functions {
    
    static var functions: [AnyFunctionBox] = [
        DefaultFunctions.sum,
        DefaultFunctions.average,
        DefaultFunctions.multiply,
        DefaultFunctions.sumRange,
        DefaultFunctions.join,
        DefaultFunctions.runJavaScript,
        DefaultFunctions.webSearch,
        DefaultFunctions.showAlert
    ]
    
}

