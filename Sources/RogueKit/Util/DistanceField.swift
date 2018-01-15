//
//  DistanceField.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/13/18.
//

import Foundation
import BearLibTerminal


class DistanceField {
  var cells: Array2D<Int>
  var maxVal: Int = 0

  init(size: BLSize) {
    self.cells = Array2D<Int>(size: size, emptyValue: Int.max)
  }

  func populate(seeds: [BLPoint], isPassable: (BLPoint) -> Bool) {
    maxVal = 0
    let rect = BLRect(x: 0, y: 0, w: cells.size.w, h: cells.size.h)
    var toVisit: [(BLPoint, Int)] = seeds.map({ ($0, 0) })

    while toVisit.count > 0 {
      let (point, val) = toVisit.removeFirst()
      if self.cells[point] <= val { continue }
      maxVal = max(maxVal, val)
      self.cells[point] = val
      for neighbor in point.getNeighbors(bounds: rect, diagonals: false) {
        if isPassable(neighbor) {
          toVisit.append((neighbor, val + 1))
        }
      }
    }
  }

  func getNormalizedValue(at point: BLPoint) -> Double? {
    let val = cells[point]
    guard val < Int.max, maxVal > 0 else { return nil }
    return 1 - (Double(val) / Double(maxVal))
  }

  func findMinimum(where filter: (BLPoint) -> Bool) -> BLPoint? {
    var minVal = Int.max
    var candidate: BLPoint? = nil
    for point in BLRect(size: cells.size) {
      if self.cells[point] < minVal && filter(point) {
        minVal = self.cells[point]
        candidate = point
      }
    }
    return candidate
  }

  func findMaximum(where filter: (BLPoint) -> Bool) -> BLPoint? {
    var minVal = Int.min
    var candidate: BLPoint? = nil
    for point in BLRect(size: cells.size) {
      if !filter(point) { continue }
      if self.cells[point] > minVal && self.cells[point] != Int.max {
        minVal = self.cells[point]
        candidate = point
      }
    }
    return candidate
  }
}

extension DistanceField: REXPaintDrawable {
  var width: Int32 { return cells.size.w }
  var height: Int32 { return cells.size.h }
  var layersCount: Int { return 1 }

  func get(layer: Int, x: Int, y: Int) -> REXPaintCell {
    if let val = getNormalizedValue(at: BLPoint(x: Int32(x), y: Int32(y))) {
      let fg = RKColor(h: 0.9 - val * 0.9, s: 1, l: 0.5).tuple
      return REXPaintCell(code: CP437.BLOCK, foregroundColor: fg, backgroundColor: (0, 0, 0))
    } else {
      return REXPaintCell.transparent
    }
  }
}
