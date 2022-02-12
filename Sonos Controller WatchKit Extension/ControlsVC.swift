//
//  ControlsVC v2.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 26/04/2021.
//

import WatchKit
import Foundation
import SwiftyXMLParser


class ControlsVC: WKInterfaceController, WKCrownDelegate {

    @IBOutlet var pauseButton: WKInterfaceButton!
    @IBOutlet var playButton: WKInterfaceButton!
    @IBOutlet var stopButton: WKInterfaceButton!
    
    @IBOutlet var nextButton: WKInterfaceButton!
    @IBOutlet var previousButton: WKInterfaceButton!
    
    @IBOutlet var deviceNameButton: WKInterfaceButton!
    @IBOutlet var slider: WKInterfaceSlider!
    
    @IBOutlet var muteButton: WKInterfaceButton!
    @IBOutlet var unMuteButton: WKInterfaceButton!

    @IBOutlet var nowPlaying: WKInterfaceLabel!
    
    var selectedDevice: SonosUPnPClient.Device?

    
//    var pause = true
    var playState: SonosUPnPClient.PlayState = .Paused
    var mute = false
    var volume: Float = -1
//    var isGroup = false
    var allowedTransportActions = ["Set", "Stop", "Play"]
    
    @IBAction func reloadDeviceData(_ sender: Any) {
        reloadDeviceData()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        crownSequencer.focus()
        crownSequencer.delegate = self
        
        if let device = context as? SonosUPnPClient.Device{
            selectedDevice = device
            print("Selected device with name: \(device.displayName ?? "no name")")
            deviceNameButton.setTitle(device.displayName)
//            self.isGroup = device.isGroup
            reloadDeviceData()
        }
    }

    func reloadDeviceData(){
        getPlayState()
        getVolume()
        getMuteState()
        getTransportActions()
        getTrackInfo()
    }
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        let difference: Float = rotationalDelta > 0 ? -0.2 : 0.2
//        print("update: ", volume - difference)
        changeVolume(newVolume: volume - difference)
    }
    
    /// Slider did change method
    @IBAction func didChange(_ value: Float) {
        changeVolume(newVolume: value)
    }
    
    
    @IBAction func mute(_ sender: WKInterfaceButton){
        changeMuteState()
        print("setting mute: \(mute)")
        selectedDevice?.setMute(mute: mute) { (_, error) in
            if let error = error{
                self.alert(title: "Kan mute staat niet veranderen!", message: "")
                print("Error updating mute: \(error.localizedDescription)")
                self.changeMuteState()
            }
        }
    }
    
    @IBAction func playPause(_ sender: WKInterfaceButton){
        let paused = playState == .Paused || playState == .Stopped
        let state: SonosUPnPClient.PlayState = paused ? .Playing : .Paused
        changePlayState(state: state)
        
        let handler = { (_ body: String?, _ error: Error?) in
            if let error = error{
                self.alert(title: "Kan niet \(paused ? "afspelen" : "pauzeren")", message: "")
                print("Error updating playstate: \(error.localizedDescription)")
                self.changePlayState(state: state == .Playing ? .Paused : .Playing)
            }
        }
        
        if(paused){
            selectedDevice?.play(handler: handler)
        }else{
            selectedDevice?.pause(handler: handler)
        }
    }
    
    @IBAction func stopPlaying(_ sender: WKInterfaceButton){
        playState = .Stopped
        
        playButton.setHidden(false)
        pauseButton.setHidden(true)
        stopButton.setHidden(true)
        
        selectedDevice?.stop { (body, error) in
            if let error = error{
                self.alert(title: "Kan niet stoppen met afspelen!", message: "")
                print("Error stopping: \(error.localizedDescription)")
                self.playState = .Playing
                self.playButton.setHidden(true)
                self.stopButton.setHidden(false)
            }
        }
    }
    
    
    @IBAction func next(_ sender: WKInterfaceButton){
        selectedDevice?.next { (_, error) in
            if let error = error{
                self.alert(title: "Kan niet een nummer vooruit gaan!", message: "")
                print("Error doing next: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func previous(_ sender: WKInterfaceButton){
        selectedDevice?.previous { (_, error) in
            if let error = error{
                self.alert(title: "Kan niet een nummer achteruit gaan!", message: "")
                print("Error doing previous: \(error.localizedDescription)")
            }
        }
    }
    
    func changeVolume(newVolume: Float, updateOnSpeaker: Bool = true){
        if Int(volume) != Int(newVolume) && newVolume >= 0 && newVolume <= 100 {
//            print("volume update: \(Int(newVolume))")
            if updateOnSpeaker {
                selectedDevice?.setVolume(newVolume: Int(newVolume)) { (body, error) in
                    if let error = error{
                        self.alert(title: "Error tijdens updaten volume", message: "Kon volume niet updaten vanwege een error!")
                        print("Error updating volume: \(error.localizedDescription)")
                    }
                }
            }
        }
        self.volume = newVolume
        self.slider.setValue(newVolume)
    }
    
    func changePlayState(state: SonosUPnPClient.PlayState){
//        pause = state == nil ? !pause : state!
        self.playState = state
        
//        playButton.setHidden(state == .Paused || state == .PausedPlayback || state == .Stopped)
        playButton.setHidden(!(playState == .Paused || playState == .Stopped))
        
        if state == .Playing && allowedTransportActions.contains("Pause"){
            pauseButton.setHidden(playState == .Paused || playState == .Stopped)
        }else{
            stopButton.setHidden(playState == .Paused || playState == .Stopped)
        }
        
    }
    
    func changeMuteState(state: Bool? = nil){
        mute = state == nil ? !mute : state!
        
        unMuteButton.setHidden(!mute)
        muteButton.setHidden(mute)
    }
    
    func getPlayState(){
        selectedDevice?.getPlaySate { (playState, error) in
            if let error = error{
                self.alert(title: "Kan playstate niet ophalen", message: "")
                print("Error getting playstate: \(error)")
            }else{
                self.changePlayState(state: playState)
            }
        }
    }
    
    func getMuteState(){
        selectedDevice?.getMute { (mute, error) in
            if let error = error{
                self.alert(title: "Kan mute status niet ophalen", message: "")
                print("Error getting mute: \(error.localizedDescription)")
            }else{
                self.changeMuteState(state: mute)
            }
        }
    }
    
    func getVolume(){
        selectedDevice?.getVolume { (volume, error) in
            if let error = error{
                self.alert(title: "Kan volume niet ophalen", message: "")
                print("Error getting volume: \(error.localizedDescription)")
            }else{
                self.changeVolume(newVolume: volume)
            }
        }
    }
    
    func getTransportActions(){
        selectedDevice?.getCurrentTransportActions { actions, error in
            guard actions != [] else {
                self.alert(title: "Kan acties niet ophalen", message: "Kan beschikbare speel acties niet ophalen")
                print("Error getting transport actions: \(error?.localizedDescription ?? "no error")")
                
                return
            }
            
            if actions.contains("Stop"){
                self.stopButton.setEnabled(true)
                self.stopButton.setBackgroundColor(.white)
                
                self.pauseButton.setEnabled(true)
                self.pauseButton.setBackgroundColor(.white)
                
                self.playButton.setEnabled(true)
                self.playButton.setBackgroundColor(.white)
            }
            
            if actions.contains("Next"){
                self.nextButton.setBackgroundColor(.white)
                self.nextButton.setEnabled(true)
            }

            if actions.contains("Previous"){
                self.previousButton.setBackgroundColor(.white)
                self.previousButton.setEnabled(true)
            }
        }
    }
    
    func getTrackInfo(){
        selectedDevice?.getCurrentTrackData(handler: { title, artist, _, error in
            if let error = error{
                self.alert(title: "Kan track info niet ophalen", message: "Kan de huidige track info niet ophalen")
                print("Error getting track info: \(error.localizedDescription)")
                return
            }
            
            var labelText = ""
            
            if let title = title{
                labelText += title
            }
            
            if let artist = artist{
                labelText += " - \(artist)"
            }
            
            self.nowPlaying.setText(labelText)
        })
    }
}

