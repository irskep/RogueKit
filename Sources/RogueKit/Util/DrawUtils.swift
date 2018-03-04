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

  class func drawBox(in terminal: BLTerminalInterface, rect: BLRect) {
    DrawUtils.drawLineVertical(
      in: terminal,
      origin: rect.origin + BLPoint(x: 0, y: 1),
      length: rect.size.h - 2)
    DrawUtils.drawLineVertical(
      in: terminal,
      origin: rect.origin + BLPoint(x: rect.size.w - 1, y: 1),
      length: rect.size.h - 2)
    DrawUtils.drawLineHorizontal(
      in: terminal,
      origin: rect.origin + BLPoint(x: 1, y: 0),
      length: rect.size.w - 2)
    DrawUtils.drawLineHorizontal(
      in: terminal,
      origin: rect.origin + BLPoint(x: 1, y: rect.size.h - 1),
      length: rect.size.w - 2)
    terminal.put(point: rect.origin, code: CP437.LINE_NW)
    terminal.put(point: rect.origin + rect.size.asPoint - BLPoint(x: 1, y: 1), code: CP437.LINE_SE)
    terminal.put(point: rect.origin + BLPoint(x: rect.size.w - 1, y: 0), code: CP437.LINE_NE)
    terminal.put(point: rect.origin + BLPoint(x: 0, y: rect.size.h - 1), code: CP437.LINE_SW)
  }
}
