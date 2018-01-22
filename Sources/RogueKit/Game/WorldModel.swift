//
//  WorldModel.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/21/18.
//

import Foundation
import BearLibTerminal


class WorldModel {
  let map: LevelMap
  let random: RKRNGProtocol

  lazy var floors: [BLPoint] = {
    var points = [BLPoint]()
    for point in BLRect(size: map.size) {
      if map.cells[point].terrain == 1 {
        points.append(point)
      }
    }
    return points
  }()

  private var _fovCache: Set<BLPoint>?
  var fovCache: Set<BLPoint> {
    guard let cache = _fovCache else {
      let newCache = _createFOVMap()
      _fovCache = newCache
      return newCache
    }
    return cache
  }
  var mapMemory = Set<BLPoint>()

  let positionS = PositionS()
  let sightS = SightS()
  let player: Int = 1

  init(random: RKRNGProtocol, map: LevelMap) {
    self.random = random
    self.map = map

    let playerPoint = random.choice(floors)
    sightS.add(entity: player, component: SightC(entity: player))
    positionS.add(entity: player, component: PositionC(entity: player, point: playerPoint))
    self.playerDidMove()
  }

  subscript(index: Int) -> PositionC? { return positionS[index] }
  subscript(index: Int) -> SightC? { return sightS[index] }

  func playerDidMove() {
    _fovCache = nil
  }

  private func _createFOVMap() -> Set<BLPoint> {
    let playerPos = positionS[player]!.point
    let playerSight = sightS[player]!
    let newCache = RecursiveShadowcastingFOVProvider()
      .getVisiblePoints(
        vantagePoint: playerPos,
        maxDistance: 30,
        getAllowsLight: {
          return playerSight.getCanSeeThrough(level: self.map, self.map.cells[$0])
        })
    return newCache
  }
}

extension WorldModel: BLTDrawable {
  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface) {
    if fovCache.contains(point) {
      map.draw(layer: layer, offset: offset, point: point, terminal: terminal)
    } else {
      terminal.foregroundColor = terminal.getColor(a: 255, r: 0, g: 0, b: 0)
      terminal.backgroundColor = terminal.getColor(a: 255, r: 0, g: 0, b: 0)
      terminal.put(point: point, code: 0)
    }

    // TODO: use a cache
    terminal.foregroundColor = terminal.getColor(a: 255, r: 0, g: 255, b: 0)
    for point in positionS.all {
      terminal.put(point: point.point, code: CP437.AT)
    }
  }

  var size: BLSize { return map.size }
  var layerIndices: [Int] { return map.layerIndices }
}
