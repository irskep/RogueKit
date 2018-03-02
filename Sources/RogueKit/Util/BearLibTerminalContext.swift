//
//  BearLibTerminalContext.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


class BLTerminalWithOffset: BLTerminalInterface {
  let terminal: BLTerminalInterface
  var offset: BLPoint

  init(terminal: BLTerminalInterface, offset: BLPoint = BLPoint.zero) {
    self.terminal = terminal
    self.offset = offset
  }

  func open() {
    terminal.open()
  }

  func close() {
    terminal.close()
  }

  func configure(_ config: String) -> Bool {
    return terminal.configure(config)
  }

  func refresh() {
    terminal.refresh()
  }

  func clear() {
    terminal.clear()
  }

  func clear(area: BLRect) {
    terminal.clear(area: area.moved(by: offset))
  }

  func crop(area: BLRect) {
    terminal.crop(area: area.moved(by: offset))
  }

  func delay(milliseconds: BLInt) {
    terminal.delay(milliseconds: milliseconds)
  }

  func measure(string: String) -> BLSize {
    return terminal.measure(string: string)
  }

  func print(point: BLPoint, string: String) -> BLSize {
    return terminal.print(point: point + offset, string: string)
  }

  func put(point: BLPoint, code: BLInt) {
    terminal.put(point: point + offset, code: code)
  }

  func put(point: BLPoint, code: BLInt, offset: BLPoint, nw: BLColor, sw: BLColor, se: BLColor, ne: BLColor) {
    terminal.put(point: point + self.offset, code: code, offset: offset, nw: nw, sw: sw, se: se, ne: ne)
  }

  func getColor(name: String) -> BLColor {
    return terminal.getColor(name: name)
  }

  func getColor(a: UInt8, r: UInt8, g: UInt8, b: UInt8) -> BLColor {
    return terminal.getColor(a: a, r: r, g: g, b: b)
  }

  func pickCode(point: BLPoint, index: BLInt) -> BLInt {
    return terminal.pickCode(point: point + offset, index: index)
  }

  func pickForegroundColor(point: BLPoint, index: BLInt) -> BLColor {
    return terminal.pickForegroundColor(point: point + offset, index: index)
  }

  func pickBackgroundColor(point: BLPoint, index: BLInt) -> BLColor {
    return terminal.pickBackgroundColor(point: point + offset, index: index)
  }

  func peek() -> Int32 {
    return terminal.peek()
  }

  func read() -> Int32 {
    return terminal.read()
  }

  func state(_ slot: Int32) -> Int32 {
    return terminal.state(slot)
  }

  func check(_ slot: Int32) -> Bool {
    return terminal.check(slot)
  }

  func readString(point: BLPoint, max: BLInt) -> String? {
    return terminal.readString(point: point + offset, max: max)
  }

  var hasInput: Bool { return terminal.hasInput }

  var layer: BLInt { get { return terminal.layer } set { terminal.layer = newValue} }

  var foregroundColor: BLColor { get { return terminal.foregroundColor } set { terminal.foregroundColor = newValue} }

  var backgroundColor: BLColor { get { return terminal.backgroundColor } set { terminal.backgroundColor = newValue} }

  var isCompositionEnabled: Bool { get { return terminal.isCompositionEnabled } set { terminal.isCompositionEnabled = newValue} }
}

extension BLTerminalInterface {
  func transform(offset: BLPoint) -> BLTerminalInterface {
    return BLTerminalWithOffset(terminal: self, offset: offset)
  }
}
