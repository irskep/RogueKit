//
//  REXPaintImage+BearLibTerminal.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/7/18.
//

import Foundation
import BearLibTerminal


public protocol REXPaintDrawable {
  var width: Int32 { get }
  var height: Int32 { get }
  var layersCount: Int { get }
  func get(layer: Int, x: Int, y: Int) -> REXPaintCell
}

public extension REXPaintDrawable {
  public func draw(in terminal: BLTerminalInterface, at point: BLPoint) {
    let transparent = terminal.getColor(a: 255, r: 255, g: 0, b: 255)
    let wasCompositing = terminal.isCompositionEnabled
    terminal.isCompositionEnabled = true
    for layer in 0..<layersCount {
      for y in 0..<height {
        for x in 0..<width {
          let cell = self.get(layer: layer, x: Int(x), y: Int(y))

          let fg = terminal.getColor(a: 255, r: cell.foregroundColor.0, g: cell.foregroundColor.1, b: cell.foregroundColor.2)
          terminal.foregroundColor = fg

          let bg = terminal.getColor(a: 255, r: cell.backgroundColor.0, g: cell.backgroundColor.1, b: cell.backgroundColor.2)
          if bg == transparent {
            terminal.backgroundColor = terminal.getColor(a: 0, r: 0, g: 0, b: 0)
          } else {
            terminal.backgroundColor = bg
          }
          terminal.put(point: point + BLPoint(x: x, y: y), code: cell.code)
        }
      }
    }
    terminal.isCompositionEnabled = wasCompositing
  }
}

extension REXPaintImage: REXPaintDrawable {
  public var layersCount: Int { return layers.count }
}
