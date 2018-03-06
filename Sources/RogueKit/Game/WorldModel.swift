//
//  WorldModel.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/21/18.
//

import Foundation
import BearLibTerminal

let SAVE_FILE_VERSION: String = "4"


typealias Entity = Int


enum WorldModelError: Error {
  case outdatedSaveFile
}


struct MapDefinition: Codable {
  let id: String
  let generatorId: String
  let exits: [String: String]  // "next"|"previous" -> mapId
}


class WorldModel: Codable {
  let version: String = SAVE_FILE_VERSION
  let rngStore: RandomSeedStore
  var resources: ResourceCollectionProtocol?
  lazy var csvDB: CSVDB = { return CSVDB(resources: resources!) }()

  var mapDefinitions = [String: MapDefinition]()
  var maps: [String: LevelMap]
  var activeMapId: String
  var activeMap: LevelMap { return maps[activeMapId]! }
  var messageLog = [String]()
  var gameHasntEnded: Bool {
    guard let playerHP = statsS[player]?.currentStats.hp, playerHP > 0 else { return false }
    return true
  }

  var positionS = PositionS()
  var sightS = SightS()
  var fovS = FOVS()
  var spriteS = SpriteS()
  var moveAfterPlayerS = MoveAfterPlayerS()
  var collectibleS = CollectibleS()
  var inventoryS = InventoryS()
  var statsS = StatsS()
  var nameS = NameS()
  var weaponS = WeaponS()
  var wieldingS = WieldingS()
  var armorS = ArmorS()
  var equipmentS = EquipmentS()
  var factionS = FactionS()

  var player: Entity = 1
  var nextEntityId: Entity = 2
  var povEntity: Entity { return player }
  var playerPos: BLPoint { return positionS[player]!.point }
  var playerInventory: [Entity] { return inventoryS[player]?.contents ?? [] }

  var debugFlags = [String: Int]()

  var waitingToTransitionToLevelId: String?

  subscript(index: Entity) -> PositionC? { return positionS[index] }
  subscript(index: Entity) -> SightC? { return sightS[index] }

  var exits: [String: String] { return mapDefinitions[activeMapId]?.exits ?? [:] }
  var mapRNG: RKRNGProtocol { return rngStore[activeMapId] }

  enum CodingKeys: String, CodingKey {
    case version
    case rngStore
    case maps
    case mapDefinitions
    case player

    case activeMapId
    case mapMemory
    case nextEntityId
    case waitingToTransitionToLevelId
    case messageLog

    case positionS
    case sightS
    case fovS
    case spriteS
    case moveAfterPlayerS
    case collectibleS
    case inventoryS
    case statsS
    case nameS
    case weaponS
    case wieldingS
    case armorS
    case equipmentS
    case factionS

    case debugFlags
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let version = try values.decode(String.self, forKey: .version)
    if version != SAVE_FILE_VERSION {
      throw WorldModelError.outdatedSaveFile
    }
    maps = try values.decode([String: LevelMap].self, forKey: .maps)
    mapDefinitions = try values.decode([String: MapDefinition].self, forKey: .mapDefinitions)
    activeMapId = try values.decode(String.self, forKey: .activeMapId)
    rngStore = try values.decode(RandomSeedStore.self, forKey: .rngStore)
    player = try values.decode(Entity.self, forKey: .player)
    nextEntityId = try values.decode(Entity.self, forKey: .nextEntityId)
    waitingToTransitionToLevelId = try? values.decode(String.self, forKey: .waitingToTransitionToLevelId)
    debugFlags = try values.decode([String: Int].self, forKey: .debugFlags)
    messageLog = try values.decode([String].self, forKey: .messageLog)

    positionS = try values.decode(PositionS.self, forKey: .positionS)
    sightS = try values.decode(SightS.self, forKey: .sightS)
    fovS = try values.decode(FOVS.self, forKey: .fovS)
    spriteS = try values.decode(SpriteS.self, forKey: .spriteS)
    moveAfterPlayerS = try values.decode(MoveAfterPlayerS.self, forKey: .moveAfterPlayerS)
    collectibleS = try values.decode(CollectibleS.self, forKey: .collectibleS)
    inventoryS = try values.decode(InventoryS.self, forKey: .inventoryS)
    statsS = try values.decode(StatsS.self, forKey: .statsS)
    nameS = try values.decode(NameS.self, forKey: .nameS)
    weaponS = try values.decode(WeaponS.self, forKey: .weaponS)
    wieldingS = try values.decode(WieldingS.self, forKey: .wieldingS)
    armorS = try values.decode(ArmorS.self, forKey: .armorS)
    equipmentS = try values.decode(EquipmentS.self, forKey: .equipmentS)
    factionS = try values.decode(FactionS.self, forKey: .factionS)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(version, forKey: .version)
    try container.encode(maps, forKey: .maps)
    try container.encode(mapDefinitions, forKey: .mapDefinitions)
    try container.encode(activeMapId, forKey: .activeMapId)
    try container.encode(rngStore, forKey: .rngStore)
    try container.encode(player, forKey: .player)
    try container.encode(nextEntityId, forKey: .nextEntityId)
    try container.encode(waitingToTransitionToLevelId, forKey: .waitingToTransitionToLevelId)
    try container.encode(debugFlags, forKey: .debugFlags)
    try container.encode(messageLog, forKey: .messageLog)

    try container.encode(positionS, forKey: .positionS)
    try container.encode(sightS, forKey: .sightS)
    try container.encode(fovS, forKey: .fovS)
    try container.encode(spriteS, forKey: .spriteS)
    try container.encode(moveAfterPlayerS, forKey: .moveAfterPlayerS)
    try container.encode(collectibleS, forKey: .collectibleS)
    try container.encode(inventoryS, forKey: .inventoryS)
    try container.encode(statsS, forKey: .statsS)
    try container.encode(nameS, forKey: .nameS)
    try container.encode(weaponS, forKey: .weaponS)
    try container.encode(wieldingS, forKey: .wieldingS)
    try container.encode(armorS, forKey: .armorS)
    try container.encode(equipmentS, forKey: .equipmentS)
    try container.encode(factionS, forKey: .factionS)
  }

  var _allSystems: [ECSRemovable] {
    return [
      positionS,
      sightS,
      fovS,
      spriteS,
      moveAfterPlayerS,
      collectibleS,
      inventoryS,
      statsS,
      nameS,
      weaponS,
      wieldingS,
      armorS,
      equipmentS,
      factionS,
    ]
  }

  init(
    rngStore: RandomSeedStore,
    resources: ResourceCollectionProtocol,
    mapDefinitions: [MapDefinition],
    activeMapId: String)
  {
    self.resources = resources
    self.rngStore = rngStore
    for md in mapDefinitions {
      self.mapDefinitions[md.id] = md
    }
    self.maps = [:]

    self.activeMapId = activeMapId

    PlayerAssembly().assemble(entity: player, worldModel: self, point: nil, levelId: nil)
  }

  func applyPOIs() {
    for poi in activeMap.pointsOfInterest {
      switch poi.kind {
      case "entrance":
        activeMap.cells[poi.point]?.feature = activeMap.featureIdsByName["entrance"]!
      case "exit":
        activeMap.cells[poi.point]?.feature = activeMap.featureIdsByName["exit"]!
      default:
        if let assembly = ASSEMBLIES[poi.kind] {
          assembly.assemble(
            entity: addEntity(),
            worldModel: self,
            point: poi.point,
            levelId: activeMapId)
        }
      }
    }
  }

  func travel(to newLevelMapId: String) {
    waitingToTransitionToLevelId = nil
    activeMapId = newLevelMapId

    for poi in activeMap.pointsOfInterest {
      switch poi.kind {
      case "playerStart":
        positionS.move(entity: player, toPoint: poi.point, onLevel: newLevelMapId)
      default: break
      }
    }
    updateFOV()
  }

  func log(_ s: String) {
    print("LOG: \(s)")
    self.messageLog.append(s)
  }

  func playerDidTakeAction() {
    updateFOV()

    // Update playerStart point of interest to reflect player's current position
    // so if they go up/down stairs they end up in the same spot again
    for i in 0..<activeMap.pointsOfInterest.count {
      if activeMap.pointsOfInterest[i].kind == "playerStart" {
        activeMap.pointsOfInterest[i].point = playerPos
      }
    }

    // Pick up any items on the ground
    for posC in positionS.all(in: activeMapId, at: playerPos) where posC.entity != nil {
      guard let entity = posC.entity, collectibleS[entity] != nil else { continue }
      self.haveEntity(player, pickUp: entity)
    }

    // Move all enemies on this level
    for c in moveAfterPlayerS.all {
      guard gameHasntEnded else { break }
      if let entity = c.entity, !isOnActiveMap(entity: entity) { continue }
      _ = c.execute(in: self)
    }
  }

  func isOnActiveMap(entity: Entity) -> Bool {
    return positionS[entity]?.levelId == activeMapId
  }

  func addEntity() -> Entity {
    let val = nextEntityId
    nextEntityId += 1
    return val
  }

  func remove(entity: Entity) {
    print("remove", entity)
    for s in _allSystems {
      s.remove(entity: entity)
    }
  }

  func updateFOV() {
    guard maps[activeMapId] != nil else { return }
    if let fovC = fovS[player] {
      fovC.reset()
      activeMap.mapMemory.formUnion(
        fovC.getFovCache(map: activeMap, positionS: positionS, sightS: sightS))
    }
  }
}

// MARK: Convenience accessors

extension WorldModel {
  func mob(at point: BLPoint) -> Entity? {
    return positionS
      .all(in: activeMapId, at: point)
      .flatMap({ $0.entity })
      .flatMap({ self.moveAfterPlayerS[$0] })
      .first?
      .entity
  }

  func fighter(at point: BLPoint, forAttacker attacker: Entity) -> Entity? {
    guard
      let attackingFaction = factionS[attacker]?.faction,
      let maybeFighter = playerPos == point ? player : mob(at: point),
      factionS[maybeFighter]?.faction != attackingFaction
      else { return nil }
    return maybeFighter
  }

  func entity(at point: BLPoint, matchingPredicate predicate: (Entity) -> Bool) -> Entity? {
    return positionS
      .all(in: activeMapId, at: point)
      .flatMap({ $0.entity })
      .flatMap({ self.spriteS[$0] })
      .sorted(by: { $0.z > $1.z })
      .first?
      .entity
  }

  func canMobSeePlayer(_ e: Entity) -> Bool {
    return self.can(entity: player, see: positionS[e]!.point)  // just use FOV cache for symmetry
  }

  func weapon(wieldedBy entity: Entity) -> WeaponDefinition? {
    return wieldingS[entity]?.weaponDefinition(in: self)
  }

  func position(of entity: Entity) -> BLPoint? {
    return positionS[entity]?.point
  }

  var playerWeaponC: WeaponC? {
    guard let wc = wieldingS[player],
      let we = wc.weaponEntity else {
        return nil
    }
    return weaponS[we]
  }

  var playerFOVCache: Set<BLPoint> {
    return fovS[player]!.getFovCache(map: activeMap, positionS: positionS, sightS: sightS)
  }
}

// MARK: Actions

extension WorldModel {

  func predictFight(attacker: Entity, defender: Entity, forUI: Bool = false) -> CombatStats? {
    guard
      let weaponC1 = weapon(wieldedBy: attacker),
      let equipmentC1 = equipmentS[attacker],
      let statsC1 = statsS[attacker],
      let posC1 = positionS[attacker],
      let weaponC2 = weapon(wieldedBy: defender),
      let equipmentC2 = equipmentS[defender],
      let statsC2 = statsS[defender],
      let posC2 = positionS[defender] else {
        return nil
    }

    let getEquipment: (EquipmentC) -> [String: ArmorC] = {
      var ret = [String: ArmorC]()
      for (k, v) in $0.slots {
        ret[k] = self.armorS[v]!
      }
      return ret
    }

    return CombatStats.predictFight(
      attacker: Combatant(
        position: posC1.point,
        weapon: weaponC1,
        equipment: getEquipment(equipmentC1),
        stats: statsC1.currentStats),
      defender: Combatant(
        position: posC2.point,
        weapon: weaponC2,
        equipment: getEquipment(equipmentC2),
        stats: statsC2.currentStats),
      forUI: forUI)
  }

  @discardableResult
  func fight(attacker: Entity, defender: Entity) -> Bool {
    guard
      let nameC1 = nameS[attacker],
      let nameC2 = nameS[defender],
//      let equipmentC1 = equipmentS[attacker],
//      let statsC1 = statsS[attacker],
//      let equipmentC2 = equipmentS[defender],
      let statsC2 = statsS[defender],
      let stats = predictFight(attacker: attacker, defender: defender)
      else {
        return false
    }
    for outcome in CombatStats.fight(rng: mapRNG, stats: stats) {
      switch outcome {
      case .miss:
        self.log("\(nameC1.name) misses \(nameC2.name)")
      case .changeStats(let slot, let statDelta, let damageSummaryString):
        statsC2.currentStats = statsC2.currentStats + statDelta
        self.log("\(nameC1.name) hits \(nameC2.name) on the \(slot) for \(damageSummaryString)")
      }
    }
    self.maybeKill(attacker)
    self.maybeKill(defender)
    return true
  }

  func maybeKill(_ entity: Entity) {
    if let statsC = statsS[entity], statsC.currentStats.hp <= 0 { self.kill(entity) }
  }

  func kill(_ entity: Entity) {
    guard let nameC1 = nameS[entity] else { fatalError("Thou hast tried to kill a nameless thing") }
    self.log("\(nameC1.name) dies")
    if let inventoryC = inventoryS[entity] {
      for item in Array(inventoryC.contents) {
        self.drop(item: item, fromInventoryOf: entity)
      }
    }
    self.remove(entity: entity)
  }

  func haveEntity(_ host: Entity, pickUp item: Entity) {
    // Remove item from map; add to player's inventory
    positionS.remove(entity: item)
    inventoryS[host]?.add(entity: item)
    if let hostNameC = nameS[host], let itemNameC = nameS[item] {
      self.log("\(hostNameC.name) picks up \(itemNameC.name)")
    }
  }

  func waitPlayer() {
    self.playerDidTakeAction()
  }

  func movePlayer(by delta: BLPoint) {
    let newPoint = playerPos + delta

    if activeMap.cells[newPoint]?.feature == activeMap.featureIdsByName["entrance"],
      let previousLevel = activeMap.definition.exits["previous"]
    {
      self.waitingToTransitionToLevelId = previousLevel
      return
    }

    if activeMap.cells[newPoint]?.feature == activeMap.featureIdsByName["exit"],
      let nextLevel = activeMap.definition.exits["next"]
    {
      self.waitingToTransitionToLevelId = nextLevel
      return
    }

    if self.push(entity: player, by: delta) {
      self.playerDidTakeAction()
    }
  }

  func equipOrWield(host: Entity, item: Entity) {
    if weaponS[item] != nil, let wieldingC = wieldingS[host] {
      if wieldingC.weaponEntity == item {
        unwield(weaponEntity: item, on: host)
      } else {
        wield(weaponEntity: item, on: host)
      }
    } else if let armorC = armorS[item], let equipmentC = equipmentS[host] {
      if equipmentC.slots[armorC.armorDefinition.slot] == item {
        equipmentC.remove(armor: item, on: armorC.armorDefinition.slot)
      } else {
        equipmentC.put(armor: item, on: armorC.armorDefinition.slot)
      }
    }
  }

  func push(entity: Entity, by delta: BLPoint) -> Bool {
    guard let point = positionS.get(entity)?.point else { return false }
    let newPoint = point + delta

    if may(entity: entity, interactAt: newPoint) {
      self.interact(entity: entity, with: newPoint)
      return true
    } else if may(entity: entity, moveTo: newPoint) {
      self.move(entity: entity, by: delta)
      return true
    } else {
      return false
    }
  }

  func move(entity: Entity, by delta: BLPoint) {
    guard let point = positionS.get(entity)?.point else { return }
    let newPoint = point + delta
    positionS.move(entity: entity, toPoint: newPoint, onLevel: activeMapId)
  }

  func may(entity: Entity, moveTo point: BLPoint) -> Bool {
    // return false if cell contains an entity with the same faction
    for posC in positionS.all(in: activeMapId, at: point) {
      guard let e = posC.entity else { continue }
      guard let f = factionS[entity]?.faction else { continue }
      if factionS[e]?.faction == f {
        return false
      }
    }
    return activeMap.getIsPassable(entity: entity, point: point)
  }

  func may(entity: Entity, interactAt point: BLPoint) -> Bool {
    guard let cell = activeMap.cells[point] else { return false }

    // feature we can interact with?
    if self.activeMap.interactions[cell.feature] != nil { return true }

    // mob we can interact with?
    if fighter(at: point, forAttacker: entity) != nil { return true }

    return false
  }

  func can(entity: Entity, see point: BLPoint) -> Bool {
    let fovCache = fovS[player]?.getFovCache(map: activeMap, positionS: positionS, sightS: sightS)
    return fovCache?.contains(point) == true
  }

  func can(entity: Entity, remember point: BLPoint) -> Bool {
    if entity == player {
      return activeMap.mapMemory.contains(point)
    } else {
      return true
    }
  }

  func drop(item: Entity, fromInventoryOf entity: Entity) {
    guard let inventoryC: InventoryC = inventoryS[entity],
      let entityPositionC: PositionC = positionS[entity]
      else { return }
    if wieldingS[entity]?.weaponEntity == item {
      wieldingS[entity]?.weaponEntity = nil
    }
    if equipmentS[entity]?.isWearing(item) == true, let armorC = armorS[item] {
      equipmentS[entity]?.remove(armor: item, on: armorC.armorDefinition.slot)
    }
    inventoryC.remove(entity: item)
    self.positionS.add(component: PositionC(
      entity: item, point: entityPositionC.point, levelId: entityPositionC.levelId))
    if let hostNameC = nameS[entity], let itemNameC = nameS[item] {
      self.log("\(hostNameC.name) drops \(itemNameC.name)")
    }
  }

  func wield(weaponEntity: Entity, on host: Entity) {
    wieldingS[host]?.weaponEntity = weaponEntity
    if host == player { playerDidTakeAction() }
  }

  func unwield(weaponEntity: Entity, on host: Entity) {
    wieldingS[host]?.weaponEntity = nil
    if host == player { playerDidTakeAction() }
  }

  func interact(entity: Entity, with point: BLPoint) {
    guard let cell = activeMap.cells[point] else { return }
    if let fighter = fighter(at: point, forAttacker: entity) {
      self.fight(attacker: entity, defender: fighter)
    } else if let interaction = activeMap.interactions[cell.feature] {
      run(interaction: interaction, entity: entity, point: point)
    }
  }

  func run(interaction: Interaction, entity: Entity, point: BLPoint) {
    let items = interaction.script.split(separator: " ")
    switch items[0] {
    case "replace_feature_with":
      let targetName = String(items[1])
      let targetId = activeMap.featureIdsByName[targetName]!
      activeMap.cells[point]?.feature = targetId
    default:
      fatalError("Can't figure out line: \(interaction.script)")
    }
    if !interaction.blocksMovement {
      positionS.move(entity: entity, toPoint: point, onLevel: activeMapId)
    }
  }
}

// MARK: Rendering

extension WorldModel: BLTDrawable {
  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface) {
    let isOmniscient = debugFlags["omniscient"] == 1

    if self.can(entity: povEntity, see: point) || isOmniscient {
      activeMap.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: true)
    } else if activeMap.mapMemory.contains(point) {
      activeMap.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: false)
    } else {
      terminal.backgroundColor = activeMap.palette["void"]
      terminal.clear(area: BLRect(origin: point + offset))
    }

    terminal.foregroundColor = activeMap.palette["lightgreen"]

    let positionCs = positionS.all(in: activeMapId, at: point)
    guard positionCs.count > 0 else { return }
    var toDraw = [SpriteC]()
    for posC in positionCs {
      guard isOmniscient || self.can(entity: povEntity, see: point),
        let e = posC.entity,
        let spriteC = spriteS[e]
        else { continue }
      toDraw.append(spriteC)
    }
    if toDraw.count > 1 {
      toDraw.sort(by: { $0.z < $1.z })
    }
    for spriteC in toDraw {
      if let int = spriteC.int {
        terminal.put(point: point, code: int)
      } else if let str = spriteC.str {
        terminal.print(point: point, string: str)
      }
    }
  }

  var size: BLSize { return activeMap.size }
  var layerIndices: [Int] { return activeMap.layerIndices }
}
