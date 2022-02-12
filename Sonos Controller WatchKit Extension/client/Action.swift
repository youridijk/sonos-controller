//
//  Action.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 12/02/2021.
//

import WatchKit

import Socket

extension SonosUPnPClient {
    
    @dynamicCallable
    public class Action {
        var serviceType: String!
        var name: String!
        var url: URL!
        
        init(service: Service, name: String){
            self.url = service.controlURL
            self.serviceType = service.serviceType
            self.name = name
        }
        
        /// Call the action using arguments. These arguments will be merged with the stored arguments en will be overridden if they already exist
        public func call(arguments: [String: String] = [:], completionHandler: @escaping (_ body: Data?, _ error: Error?) -> ()) {
//            body = arguments == [:] ? URLEncoding.httpBody : makeSoapMessage()
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            if arguments != [:]{
                request.httpBody = makeSoapMessage(arguments: arguments).data(using: .utf8)!
            }
            
            request.allHTTPHeaderFields = [
                "Content-Type": "text/xml",
                "SOAPAction": "\(serviceType!)#\(name!)"
            ]
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let response = response as? HTTPURLResponse, response.statusCode == 200{
                    completionHandler(data, error)
                }else{
                    completionHandler(data, SonosUPnPClientError.statusCodeError)
                }
            }.resume()
            
//            AF.request(request).response { response in
//                if let data = response.data{
//                    print(String(data: data, encoding: .utf8))
//                }
//                if response.response?.statusCode == 200{
//                    completionHandler(response.data, response.error)
//                }else{
//                    completionHandler(response.data, SonosUPnPClientError.statusCodeError)
//                }
//            }
        }
        
        
        public func callString(arguments: [String: String] = [:], completionHandler: @escaping (_ body: String?, _ error: Error?) -> ()) {
            call(arguments: arguments) { (data, error) in
                if let data = data, let string = String(data: data, encoding: .utf8){
                    completionHandler(string, error)
                }else{
                    completionHandler(nil,error)
                }
            }
        }
        
        private func makeSoapMessage(arguments: [String: String]) -> String{
            var argumentsString = ""
            for i in arguments{
                let arg = "<\(i.key)>\(i.value)</\(i.key)>\n"
                argumentsString += arg
            }
            
            
            let soapMessage =
                "<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>\n" +
                "<s:Body>\n" +
                "<u:\(name!) xmlns:u='\(serviceType!)'>\n" +
                argumentsString +
                "</u:\(name!)>\n" +
                "</s:Body>\n" +
                "</s:Envelope>\n"
            
            
            return soapMessage
        }
        
        func dynamicallyCall(withKeywordArguments args: [String: Any]){
            guard let arguments = args["arguments"] as? [String: String],
                  let handler = args["handler"] as? (Data?, Error?) -> () else {
                return
            }
            
            self.call(arguments: arguments, completionHandler: handler)
        }
    }
}
