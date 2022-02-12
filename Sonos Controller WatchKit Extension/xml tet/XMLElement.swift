//
//  XMLElement.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 24/01/2022.
//

import Foundation

@dynamicMemberLookup
class XMLElement: CustomStringConvertible {
    public var description: String {
        var childrenText = ""
        
        for child in children {
            childrenText += child.description
        }
        
        return """
        name: \(name)
        data: \(data ?? "no data")
        \t\(childrenText)
        """
    }
    
    public final let name: String
    public final let parent: XMLElement?
    public final var children: [XMLElement] = []
    public final let attributes: [String : String]
    public var data: String?
    
    init(name: String, parent: XMLElement?, attributes: [String: String]) {
        self.name = name
        self.parent = parent;
        self.attributes = attributes
    }
    
    public func addChild(child: XMLElement){
        self.children.append(child)
    }
    
    public func getChildByName(name: String) -> XMLElement? {
        children.first(where: { $0.name == name })
    }
    
    subscript(dynamicMember input: String) -> XMLElement? {
        return getChildByName(name: input)
    }

    subscript(name: String) -> XMLElement? {
        return getChildByName(name: name)
    }
    
    subscript(path: [String]) -> XMLElement? {
        var element: XMLElement? = self
        
        for name in path {
            guard let safeElement = element else {
                return nil
            }
            element = safeElement[name]
        }
        
        return element
    }
    
    subscript(path: String...) -> XMLElement? {
        return self[path]
    }
}
