//
//  BearLibTerminal+Geometry.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/7/18.
//

import Foundation
import BearLibTerminal


// MARK: BLTwoAxisStruct


public protocol BLTwoAxisStruct {
  var xAxis: BLInt { get }
  var yAxis: BLInt { get }
}
extension BLPoint: BLTwoAxisStruct {
  public var xAxis: BLInt { return x }
  public var yAxis: BLInt { return y }
}
extension BLSize: BLTwoAxisStruct {
  public var xAxis: BLInt { return w }
  public var yAxis: BLInt { return h }
}


// MARK: BLPoint


public func +(_ a: BLPoint, _ b: BLPoint) -> BLPoint {
  return BLPoint(x: a.x + b.x, y: a.y + b.y)
}


public func -(_ a: BLPoint, _ b: BLPoint) -> BLPoint {
  return BLPoint(x: a.x - b.x, y: a.y - b.y)
}


public func *(_ a: BLPoint, _ b: BLPoint) -> BLPoint {
  return BLPoint(x: a.x * b.x, y: a.y * b.y)
}


// MARK: BLRect


public class BLRectIterator: IteratorProtocol {
  public typealias Element = BLPoint
  var point: BLPoint
  var rect: BLRect

  init(rect: BLRect) {
    self.rect = rect
    self.point = rect.origin
  }

  public func next() -> BLRectIterator.Element? {
    if self.point.y >= self.rect.y + self.rect.h {
      return nil
    }

    let ret = self.point
    self.point.x += 1
    if self.point.x - self.rect.x >= self.rect.w {
      self.point.x = self.rect.x
      self.point.y += 1
    }
    return ret
  }
}


extension BLRect: Sequence {
  public var origin: BLPoint { return BLPoint(x: x, y: y) }
  public var size: BLSize { return BLSize(w: w, h: h) }
  var max: BLPoint { return BLPoint(x: x + w - 1, y: y + h - 1)}

  public func makeIterator() -> BLRectIterator {
    return BLRectIterator(rect: self)
  }

  public func grown(by amount: BLTwoAxisStruct) -> BLRect {
    return BLRect(x: x, y: y, w: w + amount.xAxis, h: h + amount.yAxis)
  }

  public func shrunk(by amount: BLTwoAxisStruct) -> BLRect {
    return BLRect(x: x, y: y, w: w - amount.xAxis, h: h - amount.yAxis)
  }

  public func randomPoint(_ rng: RKRNGProtocol) -> BLPoint {
    return BLPoint(x: x + BLInt(rng.get(upperBound: UInt32(w))), y: y + BLInt(rng.get(upperBound: UInt32(h))))
  }

  public func moved(to point: BLPoint) -> BLRect {
    return BLRect(x: point.x, y: point.y, w: w, h: h)
  }

  public func contains(rect: BLRect) -> Bool {
    if rect.x < x { return false }
    if rect.y < y { return false }
    if rect.max.x > max.x { return false }
    if rect.max.y > max.y { return false }
    return true
  }
}
