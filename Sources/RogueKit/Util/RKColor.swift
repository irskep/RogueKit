//
//  RKColor.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/14/18.
//

import Foundation
import BearLibTerminal


class RKColor {
  let tuple: (UInt8, UInt8, UInt8)
  lazy var asBKColor: BLColor = { return BLTerminal.main.getColor(a: 255, r: tuple.0, g: tuple.1, b: tuple.2) }()

  init(_ tuple: (UInt8, UInt8, UInt8)) {
    self.tuple = tuple
  }

  convenience init(h: Double, s: Double, l: Double) {
    // https://stackoverflow.com/questions/2353211/hsl-to-rgb-color-conversion
    guard s != 0 else {
      let val = UInt8(255 * l)
      self.init((val, val, val))
      return
    }

    let hue2rgb: (Double, Double, Double) -> Double = {
      p, q, t in
      var t = t
      if t < 0 { t += 1 }
      if t > 1 { t -= 1 }
      if t < 1/6 { return p + (q - p) * 6 * t }
      if t < 1/2 { return q }
      if t < 2/3 { return p + (q - p) * (2.0/3 - t) * 6 }
      return p
    }

    let q = l < 0.5 ? l * (1 + s) : l + s - l * s
    let p = 2 * l - q
    let r = hue2rgb(p, q, h + 1.0/3)
    let g = hue2rgb(p, q, h)
    let b = hue2rgb(p, q, h - 1.0/3)

    self.init((UInt8(255 * r), UInt8(255 * g), UInt8(255 * b)))
  }
}
