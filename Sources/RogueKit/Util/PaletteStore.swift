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

  enum CodingKeys: String, CodingKey {
    case colors
  }

  var colors: [String: BLColor]

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    colors = try values.decode([String: BLColor].self, forKey: .colors)
    _terminal = nil
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(colors, forKey: .colors)
  }

  init(terminal: BLTerminalInterface, resources: ResourceCollection, name: String) throws {
    _terminal = terminal

    self.colors = try resources.csvMap(name: "palettes/\(name)") {
      (row: StringBox) -> (String, BLColor) in
      return (row["Name"], terminal.getColor(name: row["Value"]))
    }
  }

  subscript(index: String) -> BLColor {
    if colors[index] == nil {
      print("Missing palette color: \(index)")
    }
    return colors[index] ?? (_terminal ?? BLTerminal.main).getColor(name: index)
  }
}
