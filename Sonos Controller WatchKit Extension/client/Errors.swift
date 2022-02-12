//
//  Errors.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 21/02/2021.
//

import Foundation

enum SonosUPnPClientError: Error {
    case xmlError
    case invalidMuteState
    case invalidPlayState
    case invalidVolume
    case invalidNewVolume
    case deviceInvalidBody
    case noModelName
    case subscribeFailed
    case unsubscribeFailed
    case alreadySubscribed
    case notSubsribed
    case serviceNotFound
    case socketAlreadyStarted
    case socketUnexpectedlyClosed
    case statusCodeError
    case noIPAddress
    case emptyData
    case servicesNotFound
}

extension SonosUPnPClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .xmlError:
            return NSLocalizedString("Invalid XML", comment: "The request was successful, but there was an error parsing the XML body")
        case .invalidMuteState:
            return NSLocalizedString("Invalid mute state", comment: "Could not find a valid mute state in the XML body")
        case .invalidPlayState:
            return NSLocalizedString("Invalid play state", comment: "Could not find a valid play state in the XML body")
        case .invalidVolume:
            return NSLocalizedString("Invalid volume", comment: "Could not find a valid volume in the XML body")
        case .deviceInvalidBody:
            return NSLocalizedString("Invalid body", comment: "The request succeeded, but the body is invalid")
        case .noModelName:
            return NSLocalizedString("No modelname found", comment: "Couldn't found a valid modelname in the xml body")
        case .subscribeFailed:
            return NSLocalizedString("Failed to subscribe to service", comment: "Something went wrong handling the subscribe event")
        case .alreadySubscribed:
            return NSLocalizedString("Already subscribed to service", comment: "You already subscribed to this service")
        case .unsubscribeFailed:
            return NSLocalizedString("Unsubscribe failed", comment: "The request made to the device to usubscribe failed, but the serrvice handler won't be called")
        case .serviceNotFound:
            return NSLocalizedString("Service not found", comment: "The service you provided can't be found in the service array stored in the device")
        case .notSubsribed:
            return NSLocalizedString("Not subsribed", comment: "Not subscribed to the specified service")
        case .socketAlreadyStarted:
            return NSLocalizedString("Socket already started", comment: "The TCP socket used for the subscribe events is already started")
        case .socketUnexpectedlyClosed:
            return NSLocalizedString("Socket unexpectedly closed", comment: "The TCP socket used for the subscribe events unexpectedly closed")
        case .invalidNewVolume:
            return NSLocalizedString("Invalid new volume", comment: "The volume you provided is to high or low")
        case .statusCodeError:
            return NSLocalizedString("Status code is not 200", comment: "Status code is not 200")
        case .noIPAddress:
            return NSLocalizedString("No ip address", comment: "Your WiFi IP-address can't be found")
        case .emptyData:
            return NSLocalizedString("Empty data", comment: "The response data is empty")
        case .servicesNotFound:
            return NSLocalizedString("Required services not found", comment: "Service AVTransport, RenderingControl and/or GroupRenderingControl not found")
        }
    }
}
