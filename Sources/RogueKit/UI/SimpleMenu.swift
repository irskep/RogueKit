//
//  SimpleMenu.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


class SimpleMenu {
  var rect: BLRect
  let items: [(Int32, String, () -> Void)]

  static var defaultKeys: [BLInt] = [
    BLConstant.A,
    BLConstant.B,
    BLConstant.C,
    BLConstant.D,
    BLConstant.E,
    BLConstant.F,
    BLConstant.G,
    BLConstant.H,
    BLConstant.I,
    BLConstant.J,
    BLConstant.K,
    BLConstant.L,
    BLConstant.M,
    BLConstant.N,
    BLConstant.O,
    BLConstant.P,
    BLConstant.Q,
    BLConstant.R,
    BLConstant.S,
    BLConstant.T,
    BLConstant.U,
    BLConstant.V,
    BLConstant.W,
    BLConstant.X,
    BLConstant.Y,
    BLConstant.Z,
  ]

  init(rect: BLRect, items: [(Int32, String, () -> Void)]) {
    self.rect = rect
    self.items = items
  }

  func draw(in terminal: BLTerminalInterface) {
    var y = rect.y
    terminal.foregroundColor = terminal.getColor(a: 255, r: 255, g: 255, b: 255)
    for (key, label, _) in items {
      terminal.print(
        point: BLPoint(x: rect.x, y: y),
        string: "(\(BLConstant.label(for: key) ?? "???")) \(label)")
      y += 1
    }
  }

  func handle(char: Int32) -> Bool {
    for (key, _, callback) in items {
      if key == char {
        callback()
        return true
      }
    }
    return false
  }
}
