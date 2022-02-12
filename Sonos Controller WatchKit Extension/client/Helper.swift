//
//  Helper.swift
//  Sonos Controller WatchKit Extension
//
//  Created by Youri Dijk on 21/02/2021.
//

import Foundation

extension URL {
    func getBaseUrl() -> URL{
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        components.path = ""
        return components.url!
    }

    func setPath(path: String) -> URL{
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        components.path = path
        return components.url!
    }
}
