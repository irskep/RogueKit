//
//  ECS+Scratch.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/22/18.
//

import Foundation
import BearLibTerminal


// MARK: Inventory


class InventoryC: ECSComponent, Codable {
  var entity: Entity?

  var contents: [Entity]

  init(entity: Entity?) {
    self.entity = entity
    self.contents = []
  }

  func add(entity: Entity) {
    contents.append(entity)
  }

  func remove(entity: Entity) {
    contents = contents.filter({ $0 != entity })
  }

  func volume(collectibleS: CollectibleS) -> Double {
    return contents
      .reduce(0, {
        (prev: Double, e: Entity) -> Double in
        return prev + (collectibleS[e]?.liters ?? 0)
      })
  }

  func mass(collectibleS: CollectibleS) -> Double {
    return contents
      .reduce(0, {
        (prev: Double, e: Entity) -> Double in
        return prev + (collectibleS[e]?.grams ?? 0)
      })
  }
}
class InventoryS: ECSSystem<InventoryC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Items


class CollectibleC: ECSComponent, Codable {
  var entity: Entity?
  var grams: Double = 0
  var liters: Double = 0
  var title: String = "UNINITIALIZED"
  init(entity: Entity?) {
    self.entity = entity
  }

  convenience init(entity: Entity?, grams: Double, liters: Double, title: String) {
    self.init(entity: entity)
    self.grams = grams
    self.liters = liters
    self.title = title
  }
}
class CollectibleS: ECSSystem<CollectibleC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: AI or something


class MoveAfterPlayerC: ECSComponent, Codable {
  var entity: Entity?
  var behaviorTypeString: String = "standStill"
  var behaviorType: BehaviorType { return BehaviorType(rawValue: behaviorTypeString)! }

  enum BehaviorType: String {
    case standStill = "standStill"
    case walkRandomly = "walkRandomly"
  }

  init(entity: Entity?) {
    self.entity = entity
  }

  convenience init(entity: Entity?, behaviorType: BehaviorType) {
    self.init(entity: entity)
    self.behaviorTypeString = behaviorType.rawValue
  }
}
class MoveAfterPlayerS: ECSSystem<MoveAfterPlayerC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Sprite


class SpriteC: ECSComponent, Codable {
  var entity: Entity?
  var int: BLInt?
  var str: String?
  var z: Int = 0

  init(entity: Entity?) {
    self.entity = entity
    self.int = 0
    self.str = "?"
  }

  convenience init(entity: Entity?, int: BLInt?, str: String?, z: Int) {
    self.init(entity: entity)
    self.int = int
    self.str = str
    self.z = z
  }
}
class SpriteS: ECSSystem<SpriteC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Position


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

  func move(entity: Entity, toPoint point: BLPoint, onLevel levelId: String) {
    guard let c = self[entity] else {
      assertionFailure("Missing component")
      return
    }
    if let levelId = c.levelId {
      let newValue = cache[levelId]?[c.point]?.filter({ $0 != c })
      cache[levelId]?[c.point] = newValue
    }
    c.levelId = levelId
    c.point = point
    _insert(c)
  }

  override func remove(entity: Entity) {
    if let c = self.get(entity), let levelId = c.levelId {
      let newValue = cache[levelId]?[c.point]?.filter({ $0 != c })
      cache[levelId]?[c.point] = newValue
    }
    super.remove(entity: entity)
  }

  func all(in levelId: String) -> [PositionC] {
    if let values = cache[levelId]?.values {
      return Array(values.flatMap({ $0 }))
    } else {
      return []
    }
  }

  func all(in levelId: String, at point: BLPoint) -> [PositionC] {
    return cache[levelId]?[point] ?? []
  }
}


// MARK: Sight


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


// MARK: FOV


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
