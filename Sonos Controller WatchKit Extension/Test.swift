//
//  Test.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 03/01/2021.
//

import WatchKit
import SwiftyXMLParser
import Network
import Socket

class Test: WKInterfaceController, SonosUPnPClientDelegate {
    var devices: [SonosUPnPClient.Device] = []
    
    func didFinishDiscovery(error: Error?) {
        if let error = error{
            alert(title: "ERROR", message: error.localizedDescription)
        }
//        print("DEVICES: \(client.devices.map({$0.displayName}))")
    }
    
    func didDiscoverDevice(device: SonosUPnPClient.Device) {
//        print(device.services)
        print("discoverd: ", device.displayName)
        devices.append(device)
    }
    
    var client: SonosUPnPClient!
    var socket: Socket!
    var data = Data()
//    var broadcastConnection: UDPBroadcastConnection!
    
    let message = "M-SEARCH * HTTP/1.1\r\n" +
        "MAN: \"ssdp:discover\"\r\n" +
        "HOST: 239.255.255.250:1900\r\n" +
        "ST: upnp:rootdevice\r\n" +
        "MX: 5\r\n\r\n"
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
//        client = SonosUPnPClient(errorHandler: { error in
//            print("ERR ", error)
//        })
//        client.delegate = self
    
    }
    
    var listener: NWListener!
    
    @IBOutlet var label2: WKInterfaceLabel!
    @IBOutlet var label: WKInterfaceLabel!
    @IBAction func test(_ sender: WKInterfaceButton){
        let url = URL(string: "http://192.168.1.24:1400/xml/device_description.xml")!
        
        print("done")
        return
//        let client = SonosUPnPClient { error in
//
//        }
//        client.delegate = self
//        client.discoverDevicesOld(socketPort: 1235)
//
        
        
        
//        AF.request("http://\(base).20:1400/xml/device_description.xml").response { response in
//            if response.response?.statusCode == 200 {
//                print("Found for 20")
//            }
//        }
        
//        let connection = NWConnection(host: "239.255.255.250", port: 1900, using: .udp)
//
//        connection.stateUpdateHandler = { newState in
//            if newState == .ready{
//                connection.send(content: self.message.data(using: .utf8), completion: .contentProcessed({ error in
//                    print("ERROR: \(error?.localizedDescription ?? "no error")")
//                }))
//            }
//        }
//
//        connection.receiveMessage { data, _, _, error in
//            if let error = error{
//                print(error.localizedDescription)
//            }
//
//            print(String(data: data!, encoding: .utf8) ?? "nothing")
//        }
//
//        connection.start(queue: .global())
//
//        if #available(watchOSApplicationExtension 7.0, *) {
//            let multicast = try? NWMulticastGroup(for: [.hostPort(host: "239.255.255.250", port: 1900)])
//
//            let group = NWConnectionGroup(with: multicast!, using: .udp)
//            group.setReceiveHandler { message, data, _ in
//                print(String(data: data!, encoding: .utf8) ?? "nothing")
//            }
//
//            group.start(queue: .global())
//
//            for member in multicast!.members{
//                print(member)
//            }
//        } else {
//        }
//

        let udpListener = try! NWListener(using: .udp, on: 1900)
        
        let broadcast: NWEndpoint.Host = "239.255.255.250"
        let portUDP: NWEndpoint.Port = 1900
        let localPort : NWEndpoint.Port = udpListener.port!
        let localEndpoint = NWEndpoint.hostPort(host: "10.0.0.123", port: localPort)

        let parameters = NWParameters.udp
        parameters.requiredLocalEndpoint = localEndpoint
        parameters.allowLocalEndpointReuse = true

        let connection = NWConnection(host: broadcast, port: portUDP, using: parameters)
        
        
        
        
        
        
    }
    
    @IBAction func test2(_ sender: WKInterfaceButton){
        
        
    }
    
    var services: [Service] = []
    let location = URL(string: "http://test.com")!
    
    func parseService(element: XML.Element) -> Service? {
        if let serviceType = element.childElements.first(where: {$0.name == "serviceType"})?.text,
           let controlURL = element.childElements.first(where: {$0.name == "controlURL"})?.text,
           let eventSubURL = element.childElements.first(where: {$0.name == "eventSubURL"})?.text,
           let SCPDURL = element.childElements.first(where: {$0.name == "SCPDURL"})?.text{
            print("scpdurl:", SCPDURL)
            print("scpdurl2:", self.location.setPath(path: SCPDURL))
            return Service(
                serviceType: serviceType,
                controlURL: self.location.setPath(path: controlURL),
                eventSubURL: self.location.setPath(path: eventSubURL),
                SCPDURL: self.location.setPath(path: SCPDURL)
            )
        }
        return nil
    }
    
    func parseSerivces(xmlData: Data){
        
        
        let xml = XML.parse(xmlData)
        
        if let rootServiceList = xml["root","device","serviceList","service"].all{
            for i in rootServiceList {
                if let service = parseService(element: i){
                    if !self.services.contains(where: {$0.serviceType == service.serviceType}){
                        self.services.append(service)
                    }
                }
            }
        }
        
        
        if let deviceList = xml["root","device","deviceList","device"].all{
            for i in 0...deviceList.count-1 {
                if let dServiceList = xml["root","device","deviceList","device", i, "serviceList","service"].all{
                    for s in dServiceList{
                        if let service = parseService(element: s){
                            if !self.services.contains(where: {$0.serviceType == service.serviceType}){
                                self.services.append(service)
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct Service {
        var serviceType: String!
        var controlURL: URL!
        var eventSubURL: URL!
        var SCPDURL: URL!
        var SID: String? = nil
    }
}



protocol ParserDelegate {
    func finishedParsing(xml: [String: String])
}

class MyXMLParser: NSObject, XMLParserDelegate {
    var delegate: ParserDelegate?
    var parser: XMLParser!
    
    init(xmlString: String) {
        super.init()
        let xmlData = xmlString.data(using: .utf8)!
        parser = XMLParser(data: xmlData)
                
        parser.delegate = self
                
//        parser.parse()
    }
    
    func parse(){
        parser.parse()
    }
    
    var currentElementName: String = ""
    var xml: [String: Any] = [:]
    var currentParentElement = ""
    var currentPath: [String] = []
    var previousName = ""
//    var currentArray = []
    var isArray = true
    var json = ""
    var jsonObject: [String: Any] = [:]
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
//        print("didStartElement elementName: \(elementName)")
        currentPath.append(elementName)
        self.currentElementName = elementName
        if elementName == "root"{
            json += "{\n"
        }else if json.last == ","{
            json += "\n\"\(elementName)\":{\n"
        }else{
            json += "\"\(elementName)\":{\n"
        }
        
        
        if elementName == previousName{
            if elementNamesCount[elementName] == nil{
                elementNamesCount[elementName] = 1
            }else{
                elementNamesCount[elementName]! += 1
            }
        }
        
//        if elementNamesCount[elementName] == nil{
//            elementNamesCount[elementName] = 1
//        }else{
//            elementNamesCount[elementName]! += 1
//        }
    }

    // 2
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentPath.remove(at: currentPath.count-1)
        if elementName != currentElementName{
            
            if json.last == ","{
                json.removeLast()
            }else if json.last == "\n" && Array(json)[json.count-2] == "," {
                json.removeLast()
                json.removeLast()
            }
                json += "\n},\n"
            
//            json += "}"
            
        }
        previousName = elementName
//        print("didEndElement elementName: \(elementName)")
    }

    // 3
    var elementNamesCount: [String: Int] = [:]
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        if string.replacingOccurrences(of: " ", with: "") == "\n"{
//            json += "{\n"
//            print("Path: \(currentPath) = \(string)")
        }else{
            let string = string.replacingOccurrences(of: "\n", with: "")
            json.removeLast()
            json.removeLast()
            if json.last == ":"{
                json += "\"\(string)\","
            }else{
                json += "\n\"\(string)\","
            }
//            print("Path: \(currentPath)")
        }
//        print(json)
    }
    func parserDidEndDocument(_ parser: XMLParser) {
        json.removeLast()
        json.removeLast()
        
//        var dubbleElements: [String] = []
        
        for i in elementNamesCount {
            if i.value > 1{
                print("dubble: " + i.key)
                
                let range = json.range(of: i.key)
                json = json.replacingCharacters(in: range!, with: "ThisIsTheFirst")
                json = json.replacingOccurrences(of: "\"\(i.key)\":{", with: "{")
                json = json.replacingOccurrences(of: "ThisIsTheFirst", with: "\"\(i.key)\":[")
                
//                json = json.replacingOccurrences(of: "\"serviceList\":{", with: "")
            }
        }
        let jsonData = json.data(using: .utf8)!
        
        
        print(JSONSerialization.isValidJSONObject(json))
        
        if let JSONObject = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [[String: Any]]{
            print(JSONObject)
        }
        
        print(json)
    }

}
