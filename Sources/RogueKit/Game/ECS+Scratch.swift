//
//  ECS+Scratch.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/22/18.
//

import Foundation
import BearLibTerminal


class PositionC: ECSComponent {
  var point: BLPoint
  init(entity: Int?, point: BLPoint) {
    self.point = point
    super.init(entity: entity)
  }
}
class PositionS: ECSSystem<PositionC> { }


class SightC: ECSComponent {
  var isBlind = false

  func getCanSeeThrough(level: LevelMap, _ cell: MapCell) -> Bool {
    guard !isBlind else { return false }
    return level.terrains[cell.terrain]?.canSeeThrough == true && (
      cell.feature == 0 || level.features[cell.feature]?.canSeeThrough == true
    )
  }
}
class SightS: ECSSystem<SightC> { }


class FOVC: ECSComponent {
  private var _fovCache: Set<BLPoint>?

  func reset() {
    _fovCache = nil
  }

  func getFovCache(map: LevelMap, positionS: PositionS, sightS: SightS) -> Set<BLPoint> {
    guard let cache = _fovCache else {
      let newCache = _createFOVMap(map: map, positionS: positionS, sightS: sightS)
      _fovCache = newCache
      return newCache
    }
    return cache
  }

  private func _createFOVMap(map: LevelMap, positionS: PositionS, sightS: SightS) -> Set<BLPoint> {
    guard let entity = entity else { return Set() }
    let playerPos = positionS[entity]!.point
    let playerSight = sightS[entity]!
    let newCache = RecursiveShadowcastingFOVProvider()
      .getVisiblePoints(
        vantagePoint: playerPos,
        maxDistance: 30,
        getAllowsLight: {
          return playerSight.getCanSeeThrough(level: map, map.cells[$0])
      })
    return newCache
  }
}
class FOVS: ECSSystem<FOVC> { }
