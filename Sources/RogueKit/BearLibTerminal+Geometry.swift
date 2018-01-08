//
//  BearLibTerminal+Geometry.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/7/18.
//

import Foundation
import BearLibTerminal


public func +(_ a: BLPoint, _ b: BLPoint) -> BLPoint {
  return BLPoint(x: a.x + b.x, y: a.y + b.y)
}
