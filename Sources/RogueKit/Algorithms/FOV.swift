//
//  FOV.swift
//  RLSandbox
//
//  Created by Steve Johnson on 1/3/18.
//  Copyright © 2018 Steve Johnson. All rights reserved.
//

import Foundation
import BearLibTerminal


private let MULT: [[Int32]] = [
  [1,  0,  0, -1, -1,  0,  0,  1],
  [0,  1, -1,  0,  0, -1,  1,  0],
  [0,  1,  1,  0,  0, -1, -1,  0],
  [1,  0,  0,  1, -1,  0,  0, -1],
]


protocol FOVProviding {
  func getVisiblePoints(
    vantagePoint: BLPoint,
    maxDistance: Int32,
    getAllowsLight: (BLPoint) -> Bool)
    -> Set<BLPoint>
}


class RecursiveShadowcastingFOVProvider: FOVProviding {
  func getVisiblePoints(vantagePoint: BLPoint, maxDistance: Int32, getAllowsLight: (BLPoint) -> Bool) -> Set<BLPoint> {
    var cache = Set<BLPoint>()
    cache.insert(vantagePoint)
    for region in 0..<8 {
      _castLight(
        cache: &cache,
        getAllowsLight: getAllowsLight,
        c: vantagePoint,
        row: 1,
        startSlope: 1.0,
        endSlope: 0.0,
        radius: maxDistance,
        xx: MULT[0][region],
        xy: MULT[1][region],
        yx: MULT[2][region],
        yy: MULT[3][region])
    }
    return cache
  }

  // Implementation partially borrowed from
  // https://medium.com/lateral-view/making-a-roguelike-using-ncurses-with-swift-part-1-e9f979fca998
  private func _castLight(
    cache: inout Set<BLPoint>,
    getAllowsLight: (BLPoint) -> Bool,
    c: BLPoint,
    row: Int32,
    startSlope: Double,
    endSlope: Double,
    radius: Int32,
    xx: Int32, xy: Int32, yx: Int32, yy: Int32)
  {
    if startSlope < endSlope {
      return
    }

    var startSlope = startSlope
    var nextStartSlope = startSlope

    for i: Int32 in row...radius {
      var blocked = false
      let dx: Int32 = -i, dy = -i

      for j in dx...0 {
        let lSlope : Double = (Double(j) - 0.5) / (Double(dy) + 0.5)
        let rRlope : Double = (Double(j) + 0.5) / (Double(dy) - 0.5)
        if startSlope < rRlope {
          continue
        } else if endSlope > lSlope {
          break
        }

        // Translate the dx, dy coordinates into map coordinates.
        let ax : Int32 = c.x + j * xx + dy * xy
        let ay : Int32 = c.y + j * yx + dy * yy
        let point = BLPoint(x: ax, y: ay)

        let radius2 = radius * radius
        if Int32(j * j + dy * dy) < radius2 {
          cache.insert(point)
        }

        if blocked {
          if !getAllowsLight(point) {
            nextStartSlope = rRlope
            continue
          } else {
            blocked = false
            startSlope = nextStartSlope
          }
        } else if !getAllowsLight(point) && i < radius {
          blocked = true
          _castLight(
            cache: &cache,
            getAllowsLight: getAllowsLight,
            c: c,
            row: i + 1,
            startSlope: startSlope,
            endSlope: lSlope,
            radius: radius,
            xx: xx, xy: xy, yx: yx, yy: yy)
          nextStartSlope = rRlope
        }
      }
      if blocked {
        break
      }
    }
  }
}

