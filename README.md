
# Sonos Controller
A work in pogress Apple Watch app to control your Sonos devices in your LAN. This app detects your Sonos devices in your local network and because of that, it doesn't need any account credentials. 

## UPNP
This app uses [UPNP](https://en.wikipedia.org/wiki/Universal_Plug_and_Play) to control your Sonos Devices. This is made possible using a self made library for detecting Sonos devices in your local network and controlling them. For macOS, iOS and tvOS, the library supports device detection using [SSDP](https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol) and live updates of data (volume for example) from your Sonos devices. 

## Restrictions
As far as I know, TCP and UDP sockets are NOT supported on the Apple Watch (but they do work on an Apple Watch Simulator). Because of this, the devices can't be detected using UPNP and live updates from your Sonos Devices are NOT supported. 

For device detection, the app just tries to request data from every possible IP-address in your local network using HTTP and detects the device, if the data returned is correct for an Sonos Device. 
