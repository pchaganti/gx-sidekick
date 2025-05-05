//
//  FunctionCallResult.swift
//  Sidekick
//
//  Created by John Bean on 5/5/25.
//

import Foundation

public struct FunctionCallResult: Codable {
    
    var call: String
    var result: String?
    
    var type: `Type`
    
    public enum `Type`: String, Codable, CaseIterable {
        case result
        case error
    }
    
    var description: String {
        switch self.type {
            case .result:
                return """
Below is the result produced by the tool call: `\(self.call)`.
 
```tool_call_result
\(self.result ?? "null")
```
"""
            case .error:
                return """
The function call `\(self.call)` failed, producing the error below.

```tool_call_error
\(self.result ?? "null")
```
"""
        }
    }
    
}
