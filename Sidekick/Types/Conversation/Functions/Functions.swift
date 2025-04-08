//
//  Functions.swift
//  Sidekick
//
//  Created by John Bean on 4/8/25.
//

import Foundation

enum Functions {
    
    static var functions: [AnyFunctionBox] = [
        DefaultFunctions.add,
        DefaultFunctions.average,
        DefaultFunctions.multiply,
        DefaultFunctions.join,
        DefaultFunctions.runJavaScript,
        DefaultFunctions.showAlert
    ]
    
}

