//
//  DrawUtils.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


class DrawUtils {
  class func drawLineVertical(in terminal: BLTerminalInterface, origin: BLPoint, length: BLInt) {
    for i in 0..<length {
      terminal.put(point: origin + BLPoint(x: 0, y: i), code: CP437.LINE_V)
    }
  }

  class func drawLineHorizontal(in terminal: BLTerminalInterface, origin: BLPoint, length: BLInt) {
    for i in 0..<length {
      terminal.put(point: origin + BLPoint(x: i, y: 0), code: CP437.LINE_H)
    }
  }
}
