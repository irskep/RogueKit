//
//  ECS+Scratch.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/22/18.
//

import Foundation
import BearLibTerminal


// MARK: Stats


class ActorC: ECSComponent, Codable {
  var entity: Entity?

  var definition: ActorDefinition
  var currentStats: StatBucket

  var fatigueLevel: Int {
    if currentStats.fatigue < definition.stats.fatigue * 0.75 {
      return 0
    } else if currentStats.fatigue < definition.stats.fatigue * 0.9 {
      return 1
    } else {
      return 2
    }
  }

  init(entity: Entity?) {
    self.entity = entity
    definition = ActorDefinition()
    currentStats = StatBucket()
  }

  convenience init(
    entity: Entity?,
    definition: ActorDefinition,
    currentStats: StatBucket?)
  {
    self.init(entity: entity)
    self.definition = definition
    self.currentStats = currentStats ?? definition.stats
  }
}
class ActorS: ECSSystem<ActorC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Inventory


class InventoryC: ECSComponent, Codable {
  var entity: Entity?

  var contents: [Entity]

  init(entity: Entity?) {
    self.entity = entity
    self.contents = []
  }

  func contains(entity: Entity) -> Bool {
    return contents.contains(entity)
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
  init(entity: Entity?) {
    self.entity = entity
  }

  convenience init(entity: Entity?, grams: Double, liters: Double) {
    self.init(entity: entity)
    self.grams = grams
    self.liters = liters
  }
}
class CollectibleS: ECSSystem<CollectibleC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Weapons (wielding & stats-having)


class WeaponC: ECSComponent, Codable {
  var entity: Entity?
  var weaponDefinition: WeaponDefinition

  init(entity: Entity?) {
    self.entity = entity
    self.weaponDefinition = WeaponDefinition.zero
  }

  convenience init(entity: Entity?, weaponDefinition: WeaponDefinition) {
    self.init(entity: entity)
    self.weaponDefinition = weaponDefinition
  }
}
class WeaponS: ECSSystem<WeaponC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


class WieldingC: ECSComponent, Codable {
  var entity: Entity?
  var weaponEntity: Entity?
  var defaultWeaponDefinition: WeaponDefinition

  init(entity: Entity?) {
    self.entity = entity
    self.defaultWeaponDefinition = WeaponDefinition.zero
  }

  convenience init(entity: Entity?, weaponEntity: Entity?, defaultWeaponDefinition: WeaponDefinition) {
    self.init(entity: entity)
    self.weaponEntity = weaponEntity
    self.defaultWeaponDefinition = defaultWeaponDefinition
  }

  func weaponDefinition(in worldModel: WorldModel) -> WeaponDefinition {
    if let weaponE = weaponEntity {
      return worldModel.weaponS[weaponE]!.weaponDefinition
    } else {
      return defaultWeaponDefinition
    }
  }
}
class WieldingS: ECSSystem<WieldingC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Armor (equipping & stats-having)


class ArmorC: ECSComponent, Codable {
  var entity: Entity?
  var armorDefinition: ArmorDefinition

  init(entity: Entity?) {
    self.entity = entity
    self.armorDefinition = ArmorDefinition.zero
  }

  convenience init(entity: Entity?, armorDefinition: ArmorDefinition) {
    self.init(entity: entity)
    self.armorDefinition = armorDefinition
  }
}
class ArmorS: ECSSystem<ArmorC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


class EquipmentC: ECSComponent, Codable {
  var entity: Entity?
  var slots = [String: Entity]()

  enum Slot: String {
    case body = "body"
    case head = "head"
    case hands = "hands"

    static var all: [Slot] { return [.head, .body, .hands] }
  }

  init(entity: Entity?) {
    self.entity = entity
  }

  func isWearing(_ entity: Entity) -> Bool {
    for v in slots.values {
      if v == entity { return true }
    }
    return false
  }

  func armor(on slot: Slot, in worldModel: WorldModel) -> ArmorC? {
    guard let e = slots[slot.rawValue] else { return nil }
    return worldModel.armorS[e]
  }

  func put(armor e: Entity, on slot: Slot) {
    slots[slot.rawValue] = e
  }

  func put(armor e: Entity, on slot: String) {
    self.put(armor: e, on: Slot(rawValue: slot)!)
  }

  func remove(armor e: Entity, on slot: String) {
    guard Slot(rawValue: slot) != nil else { fatalError("No such slot") }
    slots[slot] = nil
  }
}
class EquipmentS: ECSSystem<EquipmentC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Factions


class FactionC: ECSComponent, Codable {
  var faction: String = "NO FACTION"
  var entity: Entity?
  init(entity: Entity?) { self.entity = entity }
  init(entity: Entity?, faction: String) { self.entity = entity; self.faction = faction }
}
class FactionS: ECSSystem<FactionC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}


// MARK: Forced waiting


class ForceWaitC: ECSComponent, Codable {
  var turnsRemaining: Int = 0
  var entity: Entity?
  init(entity: Entity?) { self.entity = entity }
}
class ForceWaitS: ECSSystem<ForceWaitC>, Codable {
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
  var color: BLColor

  init(entity: Entity?) {
    self.entity = entity
    self.int = 0
    self.str = "?"
    self.color = 0
  }

  convenience init(entity: Entity?, int: BLInt?, str: String?, z: Int, color: BLColor) {
    self.init(entity: entity)
    self.int = int
    self.str = str
    self.z = z
    self.color = color
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

  func all(in levelId: String) -> [BLPoint: [PositionC]]? {
    return cache[levelId]
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


// MARK: Names, descriptions


class NameC: ECSComponent, Codable {
  var entity: Entity?
  var name = "UNNAMED"
  var description = "UNDESCRIBED"
  init(entity: Entity?) { self.entity = entity }
  init(entity: Entity?, name: String, description: String) { self.entity = entity; self.name = name; self.description = description }
}
class NameS: ECSSystem<NameC>, Codable {
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
