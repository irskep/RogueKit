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


private let _tDeltas: [BLPoint] = { return [
  BLPoint(x: -1, y: 0),
  BLPoint(x: 1, y: 0),
  BLPoint(x: 0, y: -1),
  BLPoint(x: 0, y: 1),
] }()
private let _xDeltas: [BLPoint] = { return [
  BLPoint(x: -1, y: -1),
  BLPoint(x: 1, y: 1),
  BLPoint(x: 1, y: -1),
  BLPoint(x: -1, y: 1),
  ] }()
public extension BLPoint {
  func getNeighbors(bounds: BLRect, diagonals: Bool) -> [BLPoint] {
    return (diagonals ? _tDeltas + _xDeltas : _tDeltas)
      .map({ self + $0 })
      .filter({ bounds.contains(point: $0) })
  }

  func manhattanDistance(to point: BLPoint) -> BLInt {
    let xdist = abs(x - point.x)
    let ydist = abs(y - point.y)
    return xdist + ydist
  }
}
extension BLPoint: CustomDebugStringConvertible {
  var rotatedClockwise: BLPoint {
    return BLPoint(x: y, y: -x)
  }

  var rotatedCounterClockwise: BLPoint {
    return BLPoint(x: -y, y: x)
  }

  public var debugDescription: String {
    return "BLPoint(\(x), \(y))"
  }

  func bresenham(to point: BLPoint) -> [BLPoint] {
    var delta = point - self
    let xsign: BLInt = delta.x > 0 ? 1 : -1
    let ysign: BLInt = delta.y > 0 ? 1 : -1

    delta.x = abs(delta.x)
    delta.y = abs(delta.y)

    var xx: BLInt = xsign
    var xy: BLInt = 0
    var yx: BLInt = 0
    var yy: BLInt = ysign
    if delta.x <= delta.y {
      let (deltax, deltay) = (delta.y, delta.x)
      delta.x = deltax
      delta.y = deltay
      xx = 0
      xy = ysign
      yx = xsign
      yy = 0
    }

    var D = 2*delta.y - delta.x
    var y = 0

    var results: [BLPoint] = []
    for x in 0..<(BLInt(delta.x) + 1) {
      let rx: BLInt = self.x + BLInt(x)*xx + BLInt(y)*yx
      let ry: BLInt = self.y + BLInt(x)*xy + BLInt(y)*yy
      results.append(BLPoint(x: BLInt(rx), y: BLInt(ry)))
      if D > 0 {
        y += 1
        D -= delta.x
      }
      D += delta.y
    }
    return results
  }
}


// MARK: BLSize


public extension BLSize {
  var asPoint: BLPoint { return BLPoint(x: w, y: h) }
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

  init(origin: BLPoint = BLPoint.zero, size: BLSize? = nil) {
    self.init(x: origin.x, y: origin.y, w: size?.w ?? 0, h: size?.h ?? 0)
  }

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

  public func moved(by delta: BLPoint) -> BLRect {
    return BLRect(x: origin.x + delta.x, y: origin.y + delta.y, w: w, h: h)
  }

  public func inset(byX1 x1: BLInt, y1: BLInt, x2: BLInt, y2: BLInt) -> BLRect {
    return BLRect(x: x + x1, y: y + y1, w: w - (x2 + x1), h: h - (y2 + y1))
  }

  public func contains(point: BLPoint) -> Bool {
    return point.x >= x && point.y >= y && point.x <= max.x && point.y <= max.y
  }

  public func contains(rect: BLRect) -> Bool {
    if rect.x < x { return false }
    if rect.y < y { return false }
    if rect.max.x > max.x { return false }
    if rect.max.y > max.y { return false }
    return true
  }
}
