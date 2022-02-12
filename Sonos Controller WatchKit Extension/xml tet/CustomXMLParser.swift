//
//  Test.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 24/01/2022.
//

import WatchKit
import Foundation

class CustomXMLParser: NSObject, XMLParserDelegate {
    
    private(set) var rootElement: XMLElement = XMLElement(name: "Root", parent: nil, attributes: [:])

    convenience init(_ xmlData: Data){
        self.init(xmlData: xmlData)
    }
    
    init(xmlData: Data){
        super.init();
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
    }
    
    convenience init(xmlString: String){
        let xmlData = xmlString.data(using: .utf8)
        self.init(xmlData: xmlData!)
    }
    
    
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let newElement =  XMLElement(name: elementName, parent: rootElement, attributes: attributeDict)
//        if(rootElement.parent != nil){
            rootElement.addChild(child: newElement)
//        }
        rootElement = newElement
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        rootElement.data = string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        if(rootElement.parent?.parent != nil){
            self.rootElement = rootElement.parent!
//        }
    }
    
    subscript(name: String) -> XMLElement? {
        return rootElement[name]
    }
    
    subscript(path: String...) -> XMLElement? {
        return rootElement[path]
    }
}

