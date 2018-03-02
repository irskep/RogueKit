//
//  ECS+Scratch.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/22/18.
//

import Foundation
import BearLibTerminal


class PositionC: ECSComponent, Codable, Equatable {
  var point: BLPoint
  var levelId: String?
  var entity: Entity?
  init(entity: Entity?) {
    self.entity = entity
    self.point = BLPoint.zero
    self.levelId = nil
  }

  convenience init(entity: Entity?, point: BLPoint, levelId: String?) {
    self.init(entity: entity)
    self.point = point
    self.levelId = levelId
  }

  static func ==(_ a: PositionC, _ b: PositionC) -> Bool {
    return a.point == b.point && a.levelId == b.levelId && a.entity == b.entity
  }
}
class PositionS: ECSSystem<PositionC>, Codable {
  var cache = [String: [BLPoint: [PositionC]]]()

  required init(from decoder: Decoder) throws {
    try super.init(from: decoder)

    cache = [String: [BLPoint: [PositionC]]]()
    for c in _all {
      _insert(c)
    }
  }

  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }

  private func _insert(_ c: PositionC) {
    guard let levelId = c.levelId else { return }
    if cache[levelId] == nil {
      cache[levelId] = [BLPoint: [PositionC]]()
    }
    if cache[levelId]?[c.point] == nil {
      cache[levelId]?[c.point] = [PositionC]()
    }
    cache[levelId]?[c.point]?.append(c)
  }

  override func add(entity: Entity, component: PositionC) {
    super.add(entity: entity, component: component)
    _insert(component)
  }

  override func remove(entity: Entity) {
    if let c = self.get(entity), let levelId = c.levelId {
      cache[levelId]?[c.point] = cache[levelId]?[c.point]?.filter({ $0 != c })
    }
    super.remove(entity: entity)
  }
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
