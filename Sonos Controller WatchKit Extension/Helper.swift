//
//  helper.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 30/12/2020.
//

import WatchKit
//
//struct Device: Codable {
//    var modelname: String!
//    var location: URL!
//    var roomName: String!
//}

extension String{
    func parseStringBetween(char1: Character, char2: Character) -> String? {
        if let index1 = self.firstIndex(of: char1),
            let index2 = self.firstIndex(of: char2) {
            return String(self[self.index(after: index1)..<index2])
//            value = value.replacingOccurrences(of: "\(char1): ", with: "")
//            value = value.replacingOccurrences(of: "\(char2): ", with: "")
//            return value
            }
            return nil
        }
}



extension WKInterfaceController{
    func alert(title: String, message: String, actions: [WKAlertAction] = []){
        let action = WKAlertAction(title: "Oke", style: WKAlertActionStyle.default){
            return
        }
        self.presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: actions == [] ? [action] : actions)
    }
}



//class UPnPAction {
//    var url: URL!
//    var service: String!
//    var action: String!
//    var arguments: [String: String]!
//    private var reqHeaders: HTTPHeaders!
//    private var body: ParameterEncoding!
//
//    init(url: URL, service: String, action: String, arguments: [String: String]){
//        self.url = url
//        self.service = service
//        self.action = action
//        self.arguments = arguments
//
//        reqHeaders = [
//            "Content-Type" : "text/xml",
//            "SOAPAction" : "\(service)#\(action)"
//        ]
//
//        body = arguments == [:] ? URLEncoding.default : makeSoapMessage(service: self.service, action: self.action, arguments: self.arguments)
//    }
//
//    func call(completionHandler: @escaping ([String: String]) -> ()) {
//        var childs: [String: String] = [:]
//        AF.request(url, method: .post, parameters: [:], encoding: body, headers: reqHeaders).response { (res) in
//            if let err = res.error{
//                print("ERROR")
//                childs = ["error": err.localizedDescription]
//                completionHandler(childs)
//                return
//            }
//
//
//            if let data = res.data {
//                let xml = XML.parse(data)
//                for i in (xml["s:Envelope", "s:Body"].all?.first?.childElements)!{
//                    if i.text == nil{
//                        for e in i.childElements{
//                            if e.text != nil{
//                                childs[e.name] = e.text
//                            }
//                        }
//                    }else{
//                        childs[i.name] = i.text
//                    }
//                }
//                print(childs)
//                print("tesst1")
//                print("names: \(String(describing: xml.names))")
//                print("TEST1")
//
//                completionHandler(childs)
//            }
//
//
//
//        }
//
//    }
//
//
//    private func makeSoapMessage(service: String, action: String, arguments: [String: String]) -> String{
//        var argumentsString = ""
//        for i in arguments{
//            let arg = "<\(i.key)>\(i.value)</\(i.key)>"
//            argumentsString += arg
//        }
//        let soapMessage =
//            "<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>" +
//            "<s:Body>" +
//            "<u:\(action) xmlns:u='\(service)'>" +
//            argumentsString +
//            "</u:\(action)>" +
//            "</s:Body>" +
//            "</s:Envelope>"
//        return soapMessage
//    }
//
//}

