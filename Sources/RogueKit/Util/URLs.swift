//
//  URLs.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation


class URLs {
  class var gameURL: URL? {
    guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return nil
    }
    return appSupportURL.appendingPathComponent("game.json")
  }
}
