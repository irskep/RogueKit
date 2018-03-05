//
//  PaletteStore.swift
//  RogueKit
//
//  Created by Steve Johnson on 2/11/18.
//

import Foundation
import BearLibTerminal


class PaletteStore: Codable {
  private var _terminal: BLTerminalInterface?

  var namedColors: [String: String]
  var colors: [String: BLColor]

  enum CodingKeys: String, CodingKey {
    case colors
    case namedColors
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    namedColors = try values.decode([String: String].self, forKey: .namedColors)
    colors = try values.decode([String: BLColor].self, forKey: .colors)
    _terminal = nil
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(colors, forKey: .colors)
    try container.encode(namedColors, forKey: .namedColors)
  }

  init(terminal: BLTerminalInterface, resources: ResourceCollectionProtocol, name: String) throws {
    _terminal = terminal

    self.namedColors = try resources.csvMap(name: "palettes/\(name)") {
      (row: StringBox) -> (String, String) in
      return (row["Name"], row["Value"])
    }

    for (k, v) in Array(self.namedColors) {
      if v.starts(with: "@") {
        self.namedColors[k] = self.namedColors[String(v.dropFirst())]
      }
    }

    var colors = [String: BLColor]()
    for (k, v) in namedColors {
      colors[k] = terminal.getColor(name: v)
    }
    self.colors = colors
  }

  func apply(to terminal: BLTerminalInterface) {
    for (k, v) in namedColors where v.hasPrefix("#") {
      terminal.configure("palette.\(k) = \(v);")
    }
  }

  subscript(index: String) -> BLColor {
    if colors[index] == nil {
      print("Missing palette color: \(index)")
    }
    return colors[index] ?? (_terminal ?? BLTerminal.main).getColor(name: index)
  }
}
