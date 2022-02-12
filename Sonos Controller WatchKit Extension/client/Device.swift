
//
//  Device.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 12/02/2021.
//

import WatchKit

import Socket
import Network

extension SonosUPnPClient{
    struct StorabelDevice{
        var modelname: String!
        var location: URL!
        var displayName: String!
    }
    
    @dynamicMemberLookup
    public class Device: Equatable {
        
        //MARK: Variabels from here
        public var displayName: String = "No name found"
        public let modelName: String
        public let modelNumber: String
        public let friendlyName: String
        public let location: URL
        public let baseLocation: URL
        public let roomName: String
        public let isSattelite: Bool
        
        private(set) var services: [Service] = []
        
        private(set) var groupUUIDS: [String] = []
        
        public let AVTransPort: Service
        public let renderingControl: Service
        public let groupRenderingControl: Service?
        
        public let xmlData: Data!
        
        public let myIP: String? = SonosUPnPClient.getWiFiAddress()
        private(set) var socketPort: Int = 1235
        
        //MARK: (de)Init from here
        
        deinit {
            #if !os(watchOS)
                self.unsubscribeAllServices()
            #endif
        }
        
        init(displayName: String? = nil, location: URL, xmlData: Data) throws {
            self.location = location
            self.xmlData = xmlData
            
            var components = URLComponents(url: location, resolvingAgainstBaseURL: false)!
            components.path = ""
            self.baseLocation = components.url!
            
            let xml = CustomXMLParser(xmlData: xmlData)
            self.services = Device.parseServices(baseLocation: self.baseLocation, xmlData: xmlData)
            
            guard let AVTransPort = Service.getServiceByName(name: "AVTransport", services: services),
                  let renderingControl = Service.getServiceByName(name: "RenderingControl", services: services),
                  let modelName = xml["root","device","modelName"]?.data,
                  let modelNumber = xml["root", "device", "modelNumber"]?.data,
                  let roomName = xml["root","device","roomName"]?.data,
                  let friendlyName = xml["root", "device", "friendlyName"]?.data
            else {
                throw SonosUPnPClientError.servicesNotFound
            }
    
            self.modelName = modelName
            self.modelNumber = modelNumber
            self.isSattelite = modelNumber == "S22"
            self.friendlyName = friendlyName
            self.roomName = roomName
            
            if let displayName = displayName {
                self.displayName = displayName
            }else{
                self.displayName = roomName
            }
            
            self.AVTransPort = AVTransPort
            self.renderingControl = renderingControl
            self.groupRenderingControl = Service.getServiceByName(name: "GroupRenderingControl", services: services)
        }
        
        public func getServiceByName(name: String) -> Service? {
            return services.first(where: {$0.serviceName == name})
        }
        
        private static func parseServices(baseLocation: URL, xmlData: Data) -> [Service]{
            var services: [Service] = []
            
            func parseService(element: XMLElement) -> Service? {
                if let serviceType = element["serviceType"]?.data,
                   let controlURL = element["controlURL"]?.data,
                   let eventSubURL = element["eventSubURL"]?.data,
                   let SCPDURL = element["SCPDURL"]?.data{
                    return Service(
                        serviceType: serviceType,
                        controlURL: baseLocation.appendingPathComponent(controlURL),
                        eventSubURL: baseLocation.appendingPathComponent(eventSubURL),
                        SCPDURL: baseLocation.appendingPathComponent(SCPDURL)
                    )
                }
                return nil
            }
            
            let xml = CustomXMLParser(xmlData: xmlData)
            
            if let rootServiceList = xml["root", "device", "serviceList"]?.children {
                for serviceElement in rootServiceList {
                    print("Element \(serviceElement.name)")
                    if let service = parseService(element: serviceElement) {
                        if !services.contains(where: {$0.serviceType == service.serviceType}){
                            services.append(service)
                        }
                    }
                }
            }
            
            if let deviceList = xml["root", "device", "deviceList"]?.children {
                for deviceElement in deviceList {
                    if let serviceList = deviceElement["serviceList"]?.children {
                        for serviceElement in serviceList {
                            if let service = parseService(element: serviceElement){
                                if !services.contains(where: {$0.serviceType == service.serviceType}){
                                    services.append(service)
                                }
                            }
                        }
                    }
                }
            }

            return services
        }
        
        
        //MARK: Pre coded common actions from here
        
        public func play(speed: String = "1", handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let playAction = Action(service: AVTransPort, name: "Play")
            playAction.callString(arguments: ["InstanceID" : "0", "Speed" : speed], completionHandler: handler)
        }
        
        public func pause(handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let pauseAction = Action(service: AVTransPort, name: "Pause")
            pauseAction.callString(arguments: ["InstanceID" : "0"], completionHandler: handler)
        }
        
        public func stop(handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let pauseAction = Action(service: AVTransPort, name: "Stop")
            pauseAction.callString(arguments: ["InstanceID" : "0"], completionHandler: handler)
        }
        
        public func next(handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let nextAction = Action(service: AVTransPort, name: "Next")
            nextAction.callString(arguments: ["InstanceID" : "0"], completionHandler: handler)
        }
        
        public func previous(handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let previousAction = Action(service: AVTransPort, name: "Previous")
            previousAction.callString(arguments: ["InstanceID" : "0"], completionHandler: handler)
        }
        
        public func setVolume(newVolume: Int, handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let args = ["InstanceID" : "0", "Channel" : "Master", "DesiredVolume" : "\(newVolume)"]
            setVolume(newVolume: newVolume, service: renderingControl, arguments: args, actionName: "SetVolume", handler: handler)
        }
        
        internal func setVolume(newVolume: Int, service: Service, arguments: [String: String], actionName: String, handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            if newVolume < 0 || newVolume > 100{
                handler(nil, SonosUPnPClientError.invalidNewVolume)
                return
            }
            let setVolumeAction = Action(service: service, name: actionName)
            setVolumeAction.callString(arguments: arguments, completionHandler: handler)
        }
        
        
        /// Get the current volume form the device. Returns -1 if there was an error.
        public func getVolume(handler: @escaping (Float, Error?) -> ()){
            let arguments = ["InstanceID" : "0", "Channel" : "Master"]
            getVolume(actionName: "GetVolume", service: renderingControl, arguments: arguments, handler: handler)
        }
        
        internal func getVolume(actionName: String, service: Service, arguments: [String: String], handler: @escaping (Float, Error?) -> ()){
            let getVolumeAction = Action(service: service, name: actionName)
            getVolumeAction.call(arguments: arguments) { (resData, err) in
                if let err = err{
                    handler(-1, err)
                    return
                }
                
                if let data = resData,
                   let volumeString = CustomXMLParser(xmlData: data)["s:Envelope", "s:Body", "u:\(actionName)Response", "CurrentVolume"]?.data,
                   let volume = Float(volumeString){
                    handler(volume,  nil)
                }else{
                    handler(-1, SonosUPnPClientError.invalidVolume)
                }
            }
        }
        
        public func setMute(mute: Bool, handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let arguments = ["InstanceID" : "0", "Channel" : "Master"]
            setMute(mute: mute, actionName: "SetMute", service: renderingControl, arguments: arguments, handler: handler)
        }
        
        public func setMute(mute: Bool, actionName: String, service: Service, arguments: [String: String], handler: @escaping (_ body: String?, _ error: Error?) -> ()){
            let boolString: String = mute ? "1" : "0"
            var editedArguments = arguments
            
            editedArguments["DesiredMute"] = "\(boolString)"
            let setMuteAction = Action(service: service, name: actionName)
            setMuteAction.callString(arguments: editedArguments, completionHandler: handler)
            
        }
        
        /// Is the device muted? Returns false and an error if there is an error
        public func getMute(handler: @escaping (_ mute: Bool, _ error: Error?) -> ()) {
            let arguments = ["InstanceID" : "0", "Channel" : "Master"]
            getMute(actionName: "GetMute", service: renderingControl, arguments: arguments, handler: handler)
        }
        
        public func getMute(actionName: String, service: Service, arguments: [String: String], handler: @escaping (_ mute: Bool, _ error: Error?) -> ()){
            let getMuteAction = Action(service: service, name: actionName)
            
            getMuteAction.call(arguments: arguments) { (res, err) in
                if let err = err {
                    handler(false, err)
                    return
                }

                if let data = res,
                   let muteString = CustomXMLParser(data)["s:Envelope", "s:Body", "u:\(actionName)Response", "CurrentMute"]?.data {
                    handler(muteString == "1", nil)
                }else{
                    handler(false, SonosUPnPClientError.invalidMuteState)
                }
            }
        }
        
        public func getPlaySate(handler: @escaping (PlayState, Error? ) -> ()) {
            self.AVTransPort.GetTransportInfo.call(arguments: ["InstanceID" : "0"]) { (resData, err) in
                if let err = err{
                    handler(.Error, err)
                    return
                }
                
                if let data = resData,
                   let state = CustomXMLParser(xmlData: data)["s:Envelope", "s:Body", "u:GetTransportInfoResponse", "CurrentTransportState"]?.data{
                    if let playState = PlayState(rawValue: state) {
                        handler(playState, nil)
                    }else if state == "PAUSED_PLAYBACK" {
                        handler(.Paused, nil)
                    }else{
                        handler(.Error, SonosUPnPClientError.invalidPlayState)
                    }
                }else{
                    handler(.Error, SonosUPnPClientError.emptyData)
                }
            }
        }
        
        public func getZoneGroupattributes(handler: @escaping (_ groupName: String, _ groupID: String, _ uudis: [String], _ error: Error?) -> ()){
            guard let zoneGroupTopology = self.ZoneGroupTopology else {
                handler("", "", [], SonosUPnPClientError.serviceNotFound)
                return
            }
            
            zoneGroupTopology.GetZoneGroupAttributes.call { (data, err) in
                    if let err = err{
                        handler("", "", [], err)
                    }else if let data = data{
                        let xml = CustomXMLParser(xmlData: data)
                        let groupID = xml["s:Envelope", "s:Body", "u:GetZoneGroupAttributesResponse", "CurrentZoneGroupID"]?.data ?? ""
                        let uudis = xml["s:Envelope", "s:Body", "u:GetZoneGroupAttributesResponse", "CurrentZonePlayerUUIDsInGroup"]?.data?.components(separatedBy: ",") ?? []
                        let groupName = xml["s:Envelope", "s:Body", "u:GetZoneGroupAttributesResponse", "CurrentZoneGroupName"]?.data ?? ""
                        handler(groupName, groupID, uudis, nil)
                    }else{
                        handler("", "", [], SonosUPnPClientError.xmlError)
                    }
                }
        }
        
        public func getGroupName(handler: @escaping (_ groupName: String, _ error: Error?) -> ()){
            getZoneGroupattributes { (groupName, _, _, err) in
                handler(groupName, err)
            }
        }
        
        public func getGroupUUIDS(handler: @escaping (_ uudis: [String], _ error: Error?) -> ()){
            getZoneGroupattributes { (_, _, uuids, err) in
                handler(uuids, err)
            }
        }
        
        public func getCurrentTransportActions(handler: @escaping (_ actions: [String], _ error: Error?) -> ()){
            self.AVTransPort.GetCurrentTransportActions.call(arguments: ["InstanceID": "0"]) { data, error in
                if let error = error{
                    handler([], error)
                    return
                }
                
                guard let data = data else {
                    handler([], SonosUPnPClientError.xmlError)
                    return
                }
                
                let xml = CustomXMLParser(xmlData: data)
                guard let actions = xml["s:Envelope", "s:Body", "u:GetCurrentTransportActionsResponse", "Actions"]?.data?.components(separatedBy: ", ") else{
                    handler([], SonosUPnPClientError.xmlError)
                    return
                }
                
                handler(actions, nil)
            }
        }
        
        /// - Parameter title: The current track title
        /// - Parameter artist: The current track artist
        /// - Parameter duration: The current track duration
        /// - Parameter Error: The error if something went wrong
        public func getCurrentTrackData(handler: @escaping (_ title: String?, _ artist: String?, _ duration: String?, _ error: Error?) -> ()){
            self.AVTransPort.GetPositionInfo.call(arguments: ["InstanceID": "0"]) { data, error in
                guard let data = data else{
                    handler(nil, nil, nil, SonosUPnPClientError.emptyData)
                    return
                }
                
                let xml = CustomXMLParser(xmlData: data)
                let getPostionInfoResponseBody = xml["s:Envelope", "s:Body", "u:GetPositionInfoResponse"]
                let trackMetaDataText = xml["s:Envelope", "s:Body", "u:GetPositionInfoResponse", "TrackMetaData"]?.data
                
                if let childElements = getPostionInfoResponseBody?.children, childElements.count > 0, trackMetaDataText == nil{
                    handler(nil, nil, nil, nil)
                    return
                }

                guard let trackMetaDataText = trackMetaDataText else {
                    handler(nil, nil, nil, SonosUPnPClientError.xmlError)
                    return
                }
                
                let trackMetaDataXML = CustomXMLParser(xmlString: trackMetaDataText)
                
                var title = trackMetaDataXML["DIDL-Lite", "item" ,"dc:title"]?.data
                    
                if title != nil{
                    title = title?.components(separatedBy: "_SC").first!
                    title = title?.components(separatedBy: "-").first!
                    title = title?.replacingOccurrences(of: "AAC_96.aac", with: "")
                }
                
                let artist = trackMetaDataXML["DIDL-Lite", "item" ,"dc:creator"]?.data
                let duration = xml["s:Envelope", "s:Body", "u:GetPositionInfoResponse", "TrackDuration"]?.data
                
                handler(title, artist, duration, nil)
            }
        }
        
        
        //MARK: Socket and subscribing stuff from here
        
        private var socket: Socket?
        public var socketOn: Bool {
            get {
                return listener != nil
            }
        }
        private var listener: NWListener?
        
        @available(watchOS, unavailable)
        public func startSocket(port: NWEndpoint.Port = 1235) throws {
            guard !socketOn else { throw SonosUPnPClientError.socketAlreadyStarted}
            
            listener = try NWListener(using: .tcp, on: port)
            
            listener?.newConnectionHandler = { (newConnection) in
                newConnection.stateUpdateHandler = { (newState) in
//                    print("STATE: ",newState)
                    if newState == .ready{
                        newConnection.send(content: "HTTP/1.1 200 OK\r\n".data(using: .utf8), completion: .contentProcessed({ error in
//                            print(error?.localizedDescription ?? "no sending error")
                            newConnection.cancel()
                        }))
                    }
                }
                
                //The TCP maximum package size is 64K 65536
                newConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536, completion: { data, _, complete, error in
                    guard let data = data, var body = String(data: data, encoding: .utf8) else {
                        return
                    }
                    
                    var headers: [String: String] = [:]
                        
                    for line in body.components(separatedBy: "\n"){
                        if line == ""{
                            break
                        }
                        if let range = line.range(of: ".*: .*", options: .regularExpression) {
                            let keyValueString = String(line[range])
                            let keyValue = keyValueString.components(separatedBy: ": ")
                            
                            headers[keyValue[0]] = keyValue[1]
                            body = body.replacingOccurrences(of: keyValueString, with: "")
                        }
                    }
                    
                    body = body.replacingOccurrences(of: "NOTIFY / HTTP/1.1", with: "")
                    body = body.replacingOccurrences(of: "\n", with: "")
                    body = body.replacingOccurrences(of: "\r", with: "")
                    
                   if let serviceName = headers["X-SONOS-SERVICETYPE"],
                      let service = self.services.first(where: {$0.serviceName == serviceName}),
                      let handler = service.subscribeCallback{
                        handler(headers, body)
                   }else{
                        print("HEAD: ", headers)
                        print(self.services.map({$0.subscribeCallback}))
                   }
                })
                
                newConnection.start(queue: .global())
            }
            
            listener?.start(queue: .global())
            
            
        }
        
        @available(watchOS, unavailable)
        public func startSocketOld(port: Int = 1235) throws{
            guard !socketOn  && socket == nil else { throw SonosUPnPClientError.socketAlreadyStarted}
            
            try socket = Socket.create()
            try socket?.listen(on: port)
            socketPort = port
//            socketOn = true
            
            DispatchQueue.global().async {
                var previousService: Service?
                while self.socketOn{
                    var data = Data()
                    do{
                        let newS = try self.socket?.acceptClientConnection()
                        let _ = try newS?.read(into: &data)
                        
                        guard var body = String(data: data, encoding: .utf8) else {
                            try newS?.write(from: "HTTP/1.1 200 OK\r\n")
                            newS?.close()
                            continue
                        }
                        var headers: [String: String] = [:]
                            
                        for line in body.components(separatedBy: "\n"){
                            if line == ""{
                                break
                            }
                            if let range = line.range(of: ".*: .*", options: .regularExpression) {
                                let keyValueString = String(line[range])
                                let keyValue = keyValueString.components(separatedBy: ": ")
                                
                                headers[keyValue[0]] = keyValue[1]
                                body = body.replacingOccurrences(of: keyValueString, with: "")
                            }
                        }
                        
                        body = body.replacingOccurrences(of: "NOTIFY / HTTP/1.1", with: "")
                        body = body.replacingOccurrences(of: "\n", with: "")
                        body = body.replacingOccurrences(of: "\r", with: "")
                        
                        if !body.contains("</e:propertyset>"){
                            if let resString = try newS?.readString(){
                                body += resString
                            }
                        }
                        
//                            print("DATA for ", headers["X-SONOS-SERVICETYPE"])
                        
                       if let serviceName = headers["X-SONOS-SERVICETYPE"],
                          let service = self.services.first(where: {$0.serviceName == serviceName}),
                          let handler = service.subscribeCallback{
                            previousService = service
                            handler(headers, body)
                       }else if headers == [:], let service = previousService, let handler = service.subscribeCallback {
                            handler(headers, body)
                       }else{
                            print("HEAD: ", headers)
                            print(self.services.map({$0.subscribeCallback}))
                       }
                        
                        try newS?.write(from: "HTTP/1.1 200 OK\r\n")
                        newS?.close()
                        
                    }catch{
                        print("Error in TCP socket: \(error)")
                    }

                }
            }
        }
        
        @available(watchOS, unavailable)
        public func stopSocket()  {
            if socketOn{
                listener?.cancel()
                listener = nil
            }
        }
        
        @available(watchOS, unavailable)
        public func subscribeToService(serviceName: String, timeout: Int = 300, serviceHandler: @escaping (_ headers: [String: String], _ body: String) -> (), completionHandler: @escaping (_ error: Error?, _ serviceName: String) -> ()){
            if let service = services.first(where: {$0.serviceName == serviceName}){
                subscribeToService(service: service, timeout: timeout, serviceHandler: serviceHandler, completionHandler: completionHandler)
            }else{
                completionHandler(SonosUPnPClientError.serviceNotFound, serviceName)
            }
        }
        
        @available(watchOS, unavailable)
        public func subscribeToService(service: Service, timeout: Int = 300, serviceHandler: @escaping (_ headers: [String: String], _ body: String) -> (), completionHandler: @escaping (_ error: Error?, _ serviceName: String) -> ()) {
            print(socketOn)
            if listener == nil {
                do{
                    try startSocket()
                }catch{
                    completionHandler(error, service.serviceName!)
                    return
                }
            }
            guard let ip = myIP else {completionHandler(SonosUPnPClientError.noIPAddress, service.serviceName!); return}
            
            guard service.SID == nil else {
                completionHandler(SonosUPnPClientError.alreadySubscribed, service.serviceName!)
                return
            }
            
            var request = URLRequest(url: service.eventSubURL)
            request.httpMethod = "SUBSCRIBE"
            request.setValue("CALLBACK", forHTTPHeaderField: "<http://\(ip):\(String(describing: socketPort))>")
            request.setValue("NT", forHTTPHeaderField: "upnp:event")
            request.setValue("TIMEOUT", forHTTPHeaderField: "Second-\(timeout)")
            
            
            URLSession.shared.dataTask(with: request) { (data, res, err) in
                if let err = err{
                    completionHandler(err, service.serviceName!)
                    return
                }
                
                guard let httpResponse = res as? HTTPURLResponse else {
                    completionHandler(SonosUPnPClientError.subscribeFailed, service.serviceName!)
                    return
                }
                
                if httpResponse.statusCode != 200{
                    completionHandler(SonosUPnPClientError.statusCodeError, service.serviceName!)
                    return
                }
                
                
                
                if let sid = httpResponse.allHeaderFields["SID"] as? String{
                    if let index = self.services.firstIndex(where: {$0.serviceType == service.serviceType}) {
                        self.services[index].SID = sid
                        self.services[index].subscribeCallback = serviceHandler
                        completionHandler(nil, service.serviceName!)
                    }else{
                        completionHandler(SonosUPnPClientError.serviceNotFound, service.serviceName!)
                    }
                }else{
                    completionHandler(SonosUPnPClientError.subscribeFailed, service.serviceName!)
                }
            }
        }
        
        @available(watchOS, unavailable)
        public func unsubscribeService(serviceName: String, completionHandler: @escaping (Error?) -> ()){
            if let service = services.first(where: {$0.serviceName == serviceName}){
                unsubscribeService(service: service, completionHandler: completionHandler)
            }else{
                completionHandler(SonosUPnPClientError.serviceNotFound)
            }
        }
        
        @available(watchOS, unavailable)
        public func unsubscribeService(service: Service, completionHandler: @escaping (Error?) -> ()){
            guard let sid = service.SID else {
                completionHandler(SonosUPnPClientError.notSubsribed)
                return
            }
            
            guard let index = self.services.firstIndex(where: {$0.serviceType == service.serviceType}) else{
                completionHandler(SonosUPnPClientError.serviceNotFound)
                return
            }
            
            services[index].SID = nil
            services[index].subscribeCallback = nil
            
            
            var request = URLRequest(url: service.eventSubURL)
            request.httpMethod = "UNSUBSCRIBE"
            request.setValue("HOST", forHTTPHeaderField: "\(self.baseLocation))")
            request.setValue("SID", forHTTPHeaderField: sid)
            
            URLSession.shared.dataTask(with: request) { (data, res, err) in
                if let err = err{
                    completionHandler(err)
                }else{
                    completionHandler(nil)
                }
            }
        }
        
        @available(watchOS, unavailable)
        public func unsubscribeAllServices() {
            stopSocket()
            
            for service in services {
                if service.SID != nil {
                    unsubscribeService(service: service, completionHandler: { (error) in
                        if let error = error{
                            print("Error unsubscribing \(service.serviceType!): \(error.localizedDescription)")
                        }
                    })
                }
            }
        }
        
        
        subscript(dynamicMember input: String) -> Service? {
            return services.first(where: {$0.serviceName == input})
        }
        
        public static func == (lhs: SonosUPnPClient.Device, rhs: SonosUPnPClient.Device) -> Bool {
            return lhs.location == rhs.location
        }
        
    }
}
