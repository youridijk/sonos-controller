////
////  ControlsVC.swift
////  Sonos Controller WatchKit Extension
////
////  Created by Youri Dijk on 28/12/2020.
////
//
//import WatchKit
//import Foundation
//
//import SwiftyXMLParser
//
//
//
//
//class ControlsVCOld: WKInterfaceController, WKCrownDelegate {
//
//    @IBOutlet var pauseButton: WKInterfaceButton!
//    @IBOutlet var playButton: WKInterfaceButton!
//    @IBOutlet var table: WKInterfaceTable!
//    @IBOutlet var slider: WKInterfaceSlider!
//    @IBOutlet var muteButton: WKInterfaceButton!
//    @IBOutlet var unMuteButton: WKInterfaceButton!
//
//
//
//    var selectedDevice: SonosUPnPClient.Device!
//
//    var avURL: URL!
//    var renderingControlURL: URL!
//
//    var pause = true
//    var mute = false
//    var volume: Float = -1 {
//        didSet{
//
//            handleVolumeChange(oldValue: oldValue)
//        }
//    }
//
//    override func awake(withContext context: Any?) {
//        super.awake(withContext: context)
//        crownSequencer.focus()
//        crownSequencer.delegate = self
//        if let device = context as? SonosUPnPClient.Device{
//            selectedDevice = device
//            table.setNumberOfRows(1, withRowType: "DeviceRow")
//            avURL = selectedDevice.location.setPath(path: "/MediaRenderer/AVTransport/Control")
//            renderingControlURL = device.location.setPath(path: "/MediaRenderer/RenderingControl/Control")
//
//            if let row = table.rowController(at: 0) as? DeviceRow{
//                row.name.setText(device.roomName)
//            }
//
//
//            let getVolAction = UPnPAction(url: renderingControlURL, service: "urn:schemas-upnp-org:service:RenderingControl:1", action: "GetVolume", arguments:["InstanceID" : "0", "Channel" : "Master"])
//            getVolAction.call { (childs) in
//                if !childs.keys.contains("s:Fault"),
//                   let percent = childs["u:GetVolumeResponse"],
//                   let floatPercent = Float(percent){
//                    self.volume = floatPercent
//                    self.slider.setValue(floatPercent)
//                }
//            }
//
//            getPlayState()
//            getMuteState()
//
//        }
//    }
//
//    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
//        volume += rotationalDelta < 0 ? -0.1 : 0.1
//        slider.setValue(volume)
//    }
//
//    @IBAction func didChange(_ value: Float) {
//        volume = value
//    }
//
//
//    @IBAction func Mute(_ sender: WKInterfaceButton){
//        changeMuteState()
//        let muteBool: String = mute ? "1" : "0"
//        print("setting mute: \(muteBool)")
//        let act = UPnPAction(url: renderingControlURL, service: "urn:schemas-upnp-org:service:RenderingControl:1", action: "SetMute", arguments:["InstanceID" : "0", "Channel" : "Master", "DesiredMute" : "\(muteBool)"])
//        act.call { (res) in
//            print("Muteres: \(res)")
//        }
//    }
//
//    @IBAction func PlayPause(_ sender: WKInterfaceButton){
//        changePlayState()
//
//        let arguments = pause ? ["InstanceID" : "0"] : ["InstanceID" : "0", "Speed" : "1"]
//        let action = UPnPAction(url: avURL, service: "urn:schemas-upnp-org:service:AVTransport:1", action: pause ? "Pause" : "Play", arguments: arguments)
//        action.call { (res) in
//            if res.keys.contains("s:Fault"){
//                self.alert(title: "Fout", message: "Er is een fout opgetreden tijdens het afpselen of pauzeren!")
//                self.changePlayState()
//            }
//        }
//
//    }
//
//
//    @IBAction func Forward(_ sender: WKInterfaceButton){
//        let action = UPnPAction(url: avURL, service: "urn:schemas-upnp-org:service:AVTransport:1", action: "Next", arguments: ["InstanceID" : "0"])
//        action.call { (res) in
//            if res.keys.contains("s:Fault"){
//                self.alert(title: "Fout", message: "Er is een fout opgetreden tijdens het volgende nummer opzetten")
//                print(res)
//            }
//        }
//    }
//
//    @IBAction func BackWard(_ sender: WKInterfaceButton){
//        print("backward")
//        let action = UPnPAction(url: avURL, service: "urn:schemas-upnp-org:service:AVTransport:1", action: "Previous", arguments: ["InstanceID" : "0"])
//        action.call { (res) in
//            if res.keys.contains("s:Fault"){
//                self.alert(title: "Fout", message: "Er is een fout opgetreden tijdens het vorige nummer opzetten")
//            }
//        }
//    }
//
//    func changePlayState(state: Bool? = nil){
//        pause = state == nil ? !pause : state!
//
//        playButton.setHidden(!pause)
//        pauseButton.setHidden(pause)
//    }
//
//    func changeMuteState(state: Bool? = nil){
//        mute = state == nil ? !mute : state!
//
//        unMuteButton.setHidden(!mute)
//        muteButton.setHidden(mute)
//    }
//
//    func getPlayState(){
//        let act = UPnPAction(url: avURL, service: "urn:schemas-upnp-org:service:AVTransport:1", action: "GetTransportInfo", arguments: ["InstanceID" : "0"])
//        act.call { (res) in
//            if let transportState = res["CurrentTransportState"]{
//                switch transportState {
//                case "PAUSE", "STOPPED":
//                    self.changePlayState(state: true)
//                    break
//                case "PLAYING":
//                    self.changePlayState(state: false)
//                    break
//                default:
//                    break
//                }
//            }
//        }
//    }
//
//    func getMuteState(){
//
//        let act = UPnPAction(url: renderingControlURL, service: "urn:schemas-upnp-org:service:RenderingControl:1", action: "GetMute", arguments:["InstanceID" : "0", "Channel" : "Master"])
//        act.call { (res) in
//            if let muteString = res["CurrentMute"]{
//                self.changeMuteState(state: muteString == "1")
//            }
//        }
//    }
//
//
//    func handleVolumeChange(oldValue: Float){
//        if Int(oldValue) != Int(volume) && oldValue != -1 && volume >= 0 && volume <= 100{
//            print("volume update: \(Int(volume))")
//            getPlayState()
////                self.label.setText("Volume: \(Int(volume))")
//            let url = selectedDevice.location.setPath(path: "/MediaRenderer/RenderingControl/Control")
//            let setVolAct = UPnPAction(url: url, service:  "urn:schemas-upnp-org:service:RenderingControl:1", action: "SetVolume", arguments: ["InstanceID" : "0", "Channel" : "Master", "DesiredVolume" : "\(Int(volume))"])
//            setVolAct.call { (res) in
//                if res.keys.contains("s:Fault"){
//                    let action = WKAlertAction(title: "Oke", style: WKAlertActionStyle.default){
//                        return
//                    }
//                    self.presentAlert(withTitle: "Fout", message: "Er was een fout tijdens het volume updaten!", preferredStyle: .alert, actions: [action])
//                }
//            }
//        }
//    }
//
//}
//
