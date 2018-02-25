//
//  ECS+Scratch.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/22/18.
//

import Foundation
import BearLibTerminal


class PositionC: ECSComponent, Codable {
  var point: BLPoint
  var entity: Entity?
  init(entity: Entity?) { self.entity = entity; self.point = BLPoint.zero }
  convenience init(entity: Entity?, point: BLPoint) {
    self.init(entity: entity)
    self.point = point
  }
}
class PositionS: ECSSystem<PositionC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


class SightC: ECSComponent, Codable {
  var isBlind = false
  var entity: Entity?
  init(entity: Entity?) { self.entity = entity }

  func getCanSeeThrough(level: LevelMap, _ cell: MapCell) -> Bool {
    guard !isBlind else { return false }
    return level.terrains[cell.terrain]?.canSeeThrough == true && (
      cell.feature == 0 || level.features[cell.feature]?.canSeeThrough == true
    )
  }
}
class SightS: ECSSystem<SightC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


class FOVC: ECSComponent, Codable {
  private var fovCache: Set<BLPoint>?
  var entity: Entity?
  init(entity: Entity?) { self.entity = entity }

  func reset() {
    fovCache = nil
  }

  func getFovCache(map: LevelMap, positionS: PositionS, sightS: SightS) -> Set<BLPoint> {
    guard let cache = fovCache else {
      let newCache = _createFOVMap(map: map, positionS: positionS, sightS: sightS)
      fovCache = newCache
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
          guard let cell = map.cells[$0] else { return false }
          return playerSight.getCanSeeThrough(level: map, cell)
      })
    return newCache
  }
}
class FOVS: ECSSystem<FOVC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}
