//
//  ListController v2.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 26/04/2021.
//

import WatchKit
import Foundation

var didDiscover = false

class ListController: WKInterfaceController, SonosUPnPClientDelegate {
    func didDiscoverDevice(device: SonosUPnPClient.Device) {
        if !devices.contains(where: {$0.displayName == device.displayName}){
            self.devices.append(device)
            
            SonosUPnPClient.storeDevicesInUserDefaults(devices: devices)
            reloadTable()
        }
        
        print("Discovered: \(device.displayName)")
    }
    
    @IBOutlet var table: WKInterfaceTable!
    
    var client: SonosUPnPClient = SonosUPnPClient()
    var devices: [SonosUPnPClient.Device] = []
//    var updateTable = true
    
    func discover(){
        do{
            try client.discoverDevices(requestTimeout: 5000, ipLimit: 225)
        }catch{
            alert(title: "Error tijdens zoeken", message: "Error tijdens het zoeken naar apparaten: \(error.localizedDescription)")
            print("error discovering: \(error.localizedDescription)")
        }
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        client.delegate = self
        
        let numberOfStoredDevices = SonosUPnPClient.getNumberOfStoredDevice()
        SonosUPnPClient.getStoredDevices { devices in
            if devices.count != numberOfStoredDevices || devices.count == 0{
                self.discover()
            }else{
                self.devices = devices
                self.reloadTable()
                self.devices.storeInUserDefaults()
                devices.searchForGroups { newDevices in
                    self.devices = newDevices
                    self.reloadTable()
                }
            }
        }
        
    }
    
    override func willActivate() {
        super.willActivate()
        // This method is called when watch view controller is about to be visible to user
        if !devices.isEmpty {
            devices.searchForGroups { newDevices in
                self.devices = newDevices
                self.reloadTable()
            }
        }
    }
    
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
//        alert(title: "Selected", message: devices[rowIndex].displayName)
        pushController(withName: "ControlsVC", context: devices[rowIndex])
    }

    func reloadTable(){
//        devices.sort { (a, b) -> Bool in
//            a.displayName < b.displayName
//        }
        
        devices.sort(by: {$0.displayName < $1.displayName})
        
        table.setNumberOfRows(devices.count, withRowType: "DeviceRow")
        for i in 0...devices.count-1 {
            if let row = table.rowController(at: i) as? DeviceRow{
                row.name.setText(devices[i].displayName)
            }
        }
    }
    
    @IBAction func longPress(_ sender: Any) {
        print("press")
        discover()
        alert(title: "Opnieuw zoeken", message: "De app gaat opnieuw zoeken naar apparaten!")
    }
}

class DeviceRow: NSObject{
    @IBOutlet var name: WKInterfaceLabel!
}

