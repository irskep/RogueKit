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

  var mapDefinitions = [String: MapDefinition]()
  var maps: [String: LevelMap]
  var activeMapId: String
  var activeMap: LevelMap { return maps[activeMapId]! }

  var positionS = PositionS()
  var sightS = SightS()
  var fovS = FOVS()
  var spriteS = SpriteS()
  var moveAfterPlayerS = MoveAfterPlayerS()

  var player: Entity = 1
  var nextEntityId: Entity = 2
  var povEntity: Entity { return player }
  var playerPos: BLPoint { return positionS[player]!.point }

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

    case positionS
    case sightS
    case fovS
    case spriteS
    case moveAfterPlayerS

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

    positionS = try values.decode(PositionS.self, forKey: .positionS)
    sightS = try values.decode(SightS.self, forKey: .sightS)
    fovS = try values.decode(FOVS.self, forKey: .fovS)
    spriteS = try values.decode(SpriteS.self, forKey: .spriteS)
    moveAfterPlayerS = try values.decode(MoveAfterPlayerS.self, forKey: .moveAfterPlayerS)

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

    try container.encode(positionS, forKey: .positionS)
    try container.encode(sightS, forKey: .sightS)
    try container.encode(fovS, forKey: .fovS)
    try container.encode(spriteS, forKey: .spriteS)
    try container.encode(moveAfterPlayerS, forKey: .moveAfterPlayerS)
  }

  init(rngStore: RandomSeedStore, mapDefinitions: [MapDefinition], activeMapId: String) {
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

  func playerDidTakeAction() {
    updateFOV()

    let playerPoint = positionS[player]!.point

    for i in 0..<activeMap.pointsOfInterest.count {
      if activeMap.pointsOfInterest[i].kind == "playerStart" {
        // if we return here, player ends up in the same spot
        activeMap.pointsOfInterest[i].point = playerPoint
      }
    }

    for c in moveAfterPlayerS.all {
      switch c.behaviorType {
      case .standStill: break
      case .walkRandomly where c.entity != nil:
        _ = AI.walkRandomly(in: self, entity: c.entity!)
      default:
        assertionFailure("Can't handle this case")
      }
    }
  }

  func addEntity() -> Entity {
    let val = nextEntityId
    nextEntityId += 1
    return val
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

extension WorldModel {
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

  func push(entity: Entity, by delta: BLPoint) -> Bool {
    guard let point = positionS.get(entity)?.point else { return false }
    let newPoint = point + delta

    if may(entity: entity, moveTo: newPoint) {
      self.move(entity: entity, by: delta)
      return true
    } else if may(entity: entity, interactAt: newPoint) {
      self.interact(entity: entity, with: newPoint)
      return true
    } else {
      return false
    }
  }

  func move(entity: Entity, by delta: BLPoint) {
    guard let point = positionS.get(entity)?.point else { return }
    let newPoint = point + delta
    positionS.get(entity)?.point = newPoint
  }

  func may(entity: Entity, moveTo point: BLPoint) -> Bool {
    return activeMap.getIsPassable(entity: entity, point: point)
  }

  func may(entity: Entity, interactAt point: BLPoint) -> Bool {
    guard let cell = activeMap.cells[point] else { return false }
    return self.activeMap.interactions[cell.feature] != nil
  }

  func can(entity: Entity, see point: BLPoint) -> Bool {
    let fovCache = fovS[player]?.getFovCache(map: activeMap, positionS: positionS, sightS: sightS)
    return fovCache?.contains(point) == true
  }

  func can(entity: Entity, remember point: BLPoint) -> Bool {
    return activeMap.mapMemory.contains(point)
  }

  func interact(entity: Entity, with point: BLPoint) {
    guard let cell = activeMap.cells[point] else { return }
    if let interaction = activeMap.interactions[cell.feature] {
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
      positionS.get(entity)?.point = point
    }
  }
}

extension WorldModel: BLTDrawable {
  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface) {
    let isOmniscient = debugFlags["omniscient"] == 1

    if self.can(entity: povEntity, see: point) || isOmniscient {
      activeMap.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: true)
    } else if activeMap.mapMemory.contains(point) {
      activeMap.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: false)
    } else {
      terminal.foregroundColor = activeMap.palette["void"]
      terminal.backgroundColor = activeMap.palette["void"]
      terminal.put(point: point, code: 0)
    }

    terminal.foregroundColor = activeMap.palette["lightgreen"]
    for posC in positionS.allInLevel(levelId: self.activeMapId)
      where (self.can(entity: povEntity, see: posC.point) || isOmniscient)
    {
      guard let entity = posC.entity,
        let spriteC = spriteS[entity]
        else { continue }
      if let int = spriteC.int {
        terminal.put(point: posC.point, code: int)
      } else if let str = spriteC.str {
        terminal.print(point: posC.point, string: str)
      }
    }
  }

  var size: BLSize { return activeMap.size }
  var layerIndices: [Int] { return activeMap.layerIndices }
}
