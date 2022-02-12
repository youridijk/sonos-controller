//
//  Service.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 21/02/2021.
//

import Foundation

extension SonosUPnPClient {
    
    @dynamicMemberLookup
    public class Service {
        private(set) var serviceType: String!
        private(set) var serviceName: String?
        private(set) var controlURL: URL!
        private(set) var eventSubURL: URL!
        private(set) var SCPDURL: URL!
        var SID: String?
        var subscribeCallback:((_ headers: [String: String], _ body:String) -> ())?
        
        public init(serviceType: String, controlURL: URL, eventSubURL: URL, SCPDURL: URL){
            self.serviceType = serviceType
            self.controlURL = controlURL
            self.eventSubURL = eventSubURL
            self.SCPDURL = SCPDURL
            
            let sT = serviceType.replacingOccurrences(of: ":1", with: "")
            if let serviceName = sT.components(separatedBy: ":").last{
                self.serviceName = serviceName
            }
        }
        
        subscript(dynamicMember input: String) -> Action{
            return Action(service: self, name: input)
        }
        
        
        public static func getServiceByName(name: String, services: [Service]) -> Service? {
            return services.first(where: {$0.serviceName == name})
        }
    }
}
