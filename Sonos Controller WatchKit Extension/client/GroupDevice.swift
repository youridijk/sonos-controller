//
//  GroupDevice.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 06/02/2022.
//

import Foundation


extension SonosUPnPClient {
    class GroupDevice: SonosUPnPClient.Device {
        override init(displayName: String? = nil, location: URL, xmlData: Data) throws {
            try super.init(displayName: displayName, location: location, xmlData: xmlData)
            if super.groupRenderingControl == nil {
                throw SonosUPnPClientError.servicesNotFound
            }
        }
        
        public override func setVolume(newVolume: Int, handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let args = ["InstanceID" : "0", "DesiredVolume" : "\(newVolume)"]
            super.setVolume(newVolume: newVolume, service: groupRenderingControl!, arguments: args, actionName: "SetGroupVolume", handler: handler)
        }
        
        public override func getVolume(handler: @escaping (Float, Error?) -> ()) {
            let arguments = ["InstanceID" : "0"]
            super.getVolume(actionName: "GetGroupVolume", service: groupRenderingControl!, arguments: arguments, handler: handler)
        }
        
        override func getMute(handler: @escaping (Bool, Error?) -> ()) {
            let arguments = ["InstanceID": "0"]
            super.getMute(actionName: "GetGroupMute", service: groupRenderingControl!, arguments: arguments, handler: handler)
        }
        
        override func setMute(mute: Bool, handler: @escaping (String?, Error?) -> ()) {
            let arguments = ["InstanceID" : "0"]
            super.setMute(mute: mute, actionName: "SetGroupMute", service: groupRenderingControl!, arguments: arguments, handler: handler)
        }
        
    }
}
