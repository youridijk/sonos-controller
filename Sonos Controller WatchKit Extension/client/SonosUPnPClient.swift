//
//  SonosUPnPClient.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 02/01/2021.
//

import WatchKit
import Socket

protocol SonosUPnPClientDelegate {
    #if !os(watchOS)
        func didFinishDiscovery(error: Error?)
    #endif
    func didDiscoverDevice(device: SonosUPnPClient.Device)
}

class SonosUPnPClient {
    public enum PlayState: String {
        case Stopped = "STOPPED"
        case Playing = "PLAYING"
        case Paused = "PAUSED"
        case Transitioning = "TRANSITIONING"
        case Error = "ERROR"
    }
    
    public var devices: [Device] = []

    private var groupsOnly: Bool = false
    private var showSatelliteSpeakers: Bool = false

    private var usedUuids: [[String]] = []

    public var delegate: SonosUPnPClientDelegate?

    private func processDevice(device: Device) {
        if !self.groupsOnly {
            if device.isSattelite {
                device.displayName = device.friendlyName
            }

            if !self.showSatelliteSpeakers && device.isSattelite {
                return
            }

            self.devices.append(device)
            self.delegate?.didDiscoverDevice(device: device)
        }

        device.getZoneGroupattributes { (groupName, _, uuids, err) in
            if err == nil && !self.usedUuids.contains(uuids) && uuids.count > 1 && groupName != "" {
//                                    groups.append(SonosGroup(location: locationURL, uuids: uuids, xmlData: data))
                self.usedUuids.append(uuids)
                if let groupDevice = try? GroupDevice(displayName: groupName, location: device.location, xmlData: device.xmlData) {
                    self.devices.append(groupDevice)
                    self.delegate?.didDiscoverDevice(device: groupDevice)
                }
            }
        }
    }

    #if os(watchOS)
    public func discoverDevices(requestTimeout: Double = 5000, groupsOnly: Bool = false, showSatelliteSpeakers: Bool = false, ipLimit: Int = 100) throws {
        guard let myIP = SonosUPnPClient.getWiFiAddress() else {
            throw SonosUPnPClientError.noIPAddress
        }

        self.groupsOnly = groupsOnly
        self.showSatelliteSpeakers = showSatelliteSpeakers

        var octets = myIP.components(separatedBy: ".")
        let myOctet = octets.removeLast()
        let base = octets.joined(separator: ".")

        for octet in 1...ipLimit {
            if "\(octet)" == myOctet {
                continue
            }

            let url = URL(string: "http://\(base).\(octet):1400/xml/device_description.xml")
            var request = URLRequest(url: url!)
            request.timeoutInterval = requestTimeout / 1000

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                      let url = response.url, let data = data else {
                    return
                }
                
                print("Succes \(url)")

                let responseXML = CustomXMLParser(xmlData: data)
                guard let modelName = responseXML["root", "device", "modelName"]?.data, modelName.contains("Sonos") else {return}
                
                do{
                    let device = try Device(location: url, xmlData: data)
                    print("DEvice found " + device.displayName)
                    self.processDevice(device: device)
                }catch{
                    print("Error \(error)")
                }
            }.resume()
        }

    }

    #else
//    public init(errorHandler: @escaping (_ error: Error) -> ()) {
//        let dataReceivedHandler = { (_ ipAddress: String, _ port: Int, _ response: Data) in
//            self.resetTimer()
//            guard let responseString = String(data: response, encoding: .utf8) else {
//                return
//            }
//
//            if let server = responseString.parseStringWith(key: "SERVER"),
//               let location = responseString.parseStringWith(key: "LOCATION"),
//               let locationURL = URL(string: location),
//               let model = server.parseStringBetween(char1: "(", char2: ")") { // ZPS22 is Sonos One SL
//
//                if !self.showSatteliteSpeakers && model == "ZPS22" {
//                    return
//                }
//                URLSession.shared.dataTask(with: locationURL) { data, response, error in
//                    if let response = response as? HTTPURLResponse, response.statusCode == 200, let url = response.url, let data = data {
//                        let device = Device(location: locationURL, xmlData: data)
//                        self.processDevice(device: device)
//                    }
//                }
//            }
//        }
//
//        do {
//            self.broadcastConnection = try UDPBroadcastConnection(port: 1900, handler: dataReveivedHandler, errorHandler: errorHandler)
//        } catch {
//            errorHandler(error)
//        }
//    }

//    public func discoverDevicesUDPLib(timeout: Double = 5000, searchTarget: String = "urn:schemas-upnp-org:device:ZonePlayer:1",
//                                      groupsOnly: Bool = false, showSatelliteSpeakers: Bool = false) {
//        self.groupsOnly = groupsOnly
//        self.showSatteliteSpeakers = showSatteliteSpeakers
//
//        let message = "M-SEARCH * HTTP/1.1\r\n" +
//            "MAN: \"ssdp:discover\"\r\n" +
//            "HOST: 239.255.255.250:1900\r\n" +
//            "ST: \(searchTarget)\r\n" +
//            "MX: 5\r\n\r\n"
//
//        do {
//            try self.broadcastConnection.sendBroadcast(message)
//            self.timerTimeout = timeout / 1000
//            resetTimer()
//        }catch{
//            self.broadcastConnection.closeConnection(reopen: false)
//            self.delegate?.didFinishDiscovery(error: error)
//        }
//    }
//
    private var timer: Timer?
    private var timerTimeout: Double = 5.0

//    private var broadcastConnection: UDPBroadcastConnection!

//    private func resetTimer() {
//        if timer != nil {
//            timer?.invalidate()
//        }
//
//        timer = Timer.scheduledTimer(withTimeInterval: timerTimeout, repeats: false) { timer in
//            self.broadcastConnection.closeConnection(reopen: false)
//            self.delegate?.didFinishDiscovery(error: nil)
//            self.usedUuids = []
//            print("Discovery stopped")
//        }
//    }

    public func discoverDevices(timeout: UInt = 5000, socketPort: Int, searchTarget: String = "urn:schemas-upnp-org:device:ZonePlayer:1",
                                 groupsOnly: Bool = false, showSatteliteSpeakers: Bool = false) {

        self.groupsOnly = groupsOnly
        self.showSatteliteSpeakers = showSatteliteSpeakers

        DispatchQueue.global().async {
            let message = "M-SEARCH * HTTP/1.1\r\n" +
                    "MAN: \"ssdp:discover\"\r\n" +
                    "HOST: 192.168.1.20:1900\r\n" +
                    "ST: \(searchTarget)\r\n" +
                    "MX: 5\r\n\r\n"

            do {
                self.isDiscovering = true
                self.searchSocket = try Socket.create(type: .datagram, proto: .udp)
                try self.searchSocket.listen(on: socketPort)
                try self.searchSocket.setReadTimeout(value: timeout) // Time in milliseconds
                try self.searchSocket?.write(from: message, to: Socket.createAddress(for: "192.168.1.20", on: 1900)!)

                self.devices = []

                //            var groups = [[URL: [String]]]()

                var usedUuids: [[String]] = []

                while self.isDiscovering {
                    var data = Data()
                    let _ = try self.searchSocket!.readDatagram(into: &data)

                    guard let responseString = String(data: data, encoding: .utf8) else {
                        continue
                    }
                    print(responseString.parseStringWith(key: "LOCATION"))
                    if let server = responseString.parseStringWith(key: "SERVER"),
                       let location = responseString.parseStringWith(key: "LOCATION"),
                       let locationURL = URL(string: location),
                       let model = server.parseStringBetween(char1: "(", char2: ")") { // ZPS22 is Sonos One SL
                        if !showSatteliteSpeakers && model == "ZPS22" {
                            continue
                        }
                        AF.request(location).response { (res) in
                            if res.error == nil, let data = res.data {
                                let device = Device(location: locationURL, xmlData: data)

                                self.processDevice(device: device)
                            }
                        }
                    } else if responseString == "" {
                        self.isDiscovering = false
                    }
                }
                self.delegate?.didFinishDiscovery(error: nil)
                self.searchSocket = nil
            } catch {
                self.delegate?.didFinishDiscovery(error: error)
            }
        }
    }
    #endif

    /// Stores the locations of the devices and the number of devices, filters group out of it
    ///- Parameter devices: The devices to be stored
    public static func storeDevicesInUserDefaults(devices: [Device]) {
        let storeableDevices: [String] = devices
                .filter({ !($0  is GroupDevice) })
                .map({ $0.location.absoluteString })
        UserDefaults.standard.set(storeableDevices, forKey: "device_locations")
        UserDefaults.standard.set(storeableDevices.count, forKey: "device_locations_count")
    }

    /// Gets the stored device location
    public static func getStoredDeviceLocations() -> [URL] {
        guard let locations = UserDefaults.standard.stringArray(forKey: "device_locations") else {
            return []
        }
        return locations.map({ URL(string: $0)! })
    }

    /// Gets the number of stored devices (stored as seperate key)
    public static func getNumberOfStoredDevice() -> Int {
        return UserDefaults.standard.integer(forKey: "device_locations_count")
    }

    /// Gets the stored device locations and donwloads the data from the location.
    /// - Parameter completionHandler: The completionHandler to execute when all the data of the devices is downloaded
    /// - Parameter devices: The found devces
    public static func getStoredDevices(completionHandler: @escaping (_ devices: [Device]) -> ()) {
        let locations = SonosUPnPClient.getStoredDeviceLocations()

        guard !locations.isEmpty else {
            completionHandler([])
            return
        }

        var counter = 0
        var devices: [Device] = []

        for location in locations {
            URLSession.shared.dataTask(with: location) { data, response, error in
                        counter += 1
                        if let data = data, error == nil,
                           let response = response as? HTTPURLResponse,
                           response.statusCode == 200 {
                            if let device = try? Device(location: location, xmlData: data) {
                                devices.append(device)
                            }
                        }

                        if counter == locations.count {
                            completionHandler(devices)
                        }
                    }
                    .resume()
        }
    }

    public static func searchForGroups(with devices: [SonosUPnPClient.Device], completionHandler: @escaping (_ devices: [SonosUPnPClient.Device]) -> ()) {
        var returnDevices = devices.filter({ !($0 is GroupDevice) })
        var usedUuids: [[String]] = []
        var counter = 0

        for device in devices {
            device.getZoneGroupattributes { (groupName, _, uuids, err) in
                counter += 1
                if err == nil && !usedUuids.contains(uuids) && uuids.count > 1 && groupName != "" {
                    usedUuids.append(uuids)

                    if let groupDevice = try? GroupDevice(displayName: groupName, location: device.location, xmlData: device.xmlData) {
                        returnDevices.append(groupDevice)
                    }
                }
                if counter == devices.count {
                    completionHandler(returnDevices)
                }
            }
        }
    }

    /// Return IP address of WiFi interface (en0) as a String, or nil
    /// Made by  Martin R on  https://stackoverflow.com/a/30754194
    public static func getWiFiAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
        }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == "en0" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
}


extension Array where Element == SonosUPnPClient.Device {
    func searchForGroups(completionHandler: @escaping (_ devices: [SonosUPnPClient.Device]) -> ()) {
        SonosUPnPClient.searchForGroups(with: self, completionHandler: completionHandler)
    }

    func storeInUserDefaults() {
        SonosUPnPClient.storeDevicesInUserDefaults(devices: self)
    }
}
