//
//  RecursiveShadowcastingFOVProvider.swift
//
//  Copyright (c) 2018, Steve Johnson
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

