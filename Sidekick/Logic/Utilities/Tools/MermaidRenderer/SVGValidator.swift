//
//  SVGValidator.swift
//  Sidekick
//
//  Created by John Bean on 5/18/25.
//

import Foundation

import Foundation

class SVGValidator {
    
    static func validateSVG(at url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let parser = XMLParser(data: data)
            let delegate = SVGXMLParserDelegate()
            parser.delegate = delegate
            
            if parser.parse(), delegate.isSVGRootFound {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
}

private class SVGXMLParserDelegate: NSObject, XMLParserDelegate {
    
    var isSVGRootFound = false
    private var didCheckRoot = false
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        if !didCheckRoot {
            didCheckRoot = true
            isSVGRootFound = (elementName.lowercased() == "svg")
        }
    }
    
}
