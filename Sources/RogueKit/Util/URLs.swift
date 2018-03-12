//
//  URLs.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation


class URLs {
  class var gameURL: URL? {
    #if os(OSX)
    guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return nil
    }
    #else
      let appSupportURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config").appendingPathComponent("dr-hallervorden")
      if !FileManager.default.fileExists(atPath: appSupportURL.path) {
        do {
          try FileManager.default.createDirectory(atPath: appSupportURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch let e {
          print(e)
          fatalError("Can't create save directory")
        }
      }
    #endif
    return appSupportURL.appendingPathComponent("game.json")
  }
}
