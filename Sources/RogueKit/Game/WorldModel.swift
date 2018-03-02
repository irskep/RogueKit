//
//  WorldModel.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/21/18.
//

import Foundation
import BearLibTerminal

let SAVE_FILE_VERSION: String = "1"


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

  var player: Entity = 1
  var povEntity: Entity { return player }

  subscript(index: Entity) -> PositionC? { return positionS[index] }
  subscript(index: Entity) -> SightC? { return sightS[index] }

  var exits: [String: String] { return mapDefinitions[activeMapId]?.exits ?? [:] }

  enum CodingKeys: String, CodingKey {
    case maps
    case mapDefinitions
    case activeMapId
    case rngStore
    case mapMemory
    case positionS
    case sightS
    case fovS
    case player
    case version
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
    positionS = try values.decode(PositionS.self, forKey: .positionS)
    sightS = try values.decode(SightS.self, forKey: .sightS)
    fovS = try values.decode(FOVS.self, forKey: .fovS)
    player = try values.decode(Entity.self, forKey: .player)

  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(version, forKey: .version)
    try container.encode(maps, forKey: .maps)
    try container.encode(mapDefinitions, forKey: .mapDefinitions)
    try container.encode(activeMapId, forKey: .activeMapId)
    try container.encode(rngStore, forKey: .rngStore)
    try container.encode(positionS, forKey: .positionS)
    try container.encode(sightS, forKey: .sightS)
    try container.encode(fovS, forKey: .fovS)
    try container.encode(player, forKey: .player)
  }

  init(rngStore: RandomSeedStore, mapDefinitions: [MapDefinition], activeMapId: String) {
    self.rngStore = rngStore
    for md in mapDefinitions {
      self.mapDefinitions[md.id] = md
    }
    self.maps = [:]

    self.activeMapId = activeMapId
    sightS.add(entity: player, component: SightC(entity: player))
    positionS.add(entity: player, component: PositionC(entity: player, point: BLPoint.zero, levelId: "UNSET"))
    fovS.add(entity: player, component: FOVC(entity: player))
  }

  func travel(to newLevelMapId: String) {
    activeMapId = newLevelMapId
    positionS[player]!.point = activeMap.pointsOfInterest["playerStart"]!
    positionS[player]!.levelId = newLevelMapId
    updateFOV()
  }

  func playerDidTakeAction() {
    updateFOV()
    activeMap.pointsOfInterest["playerStart"] = positionS[player]!.point
  }

  func updateFOV() {
    guard maps[activeMapId] != nil else { return }
    if let fovC = fovS[player] {
      fovC.reset()
      activeMap.mapMemory.formUnion(fovC.getFovCache(map: activeMap, positionS: positionS, sightS: sightS))
    }
  }
}

extension WorldModel {
  func movePlayer(by delta: BLPoint) {
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
    if self.can(entity: player, see: point) {
      activeMap.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: true)
    } else if activeMap.mapMemory.contains(point) {
      activeMap.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: false)
    } else {
      terminal.foregroundColor = activeMap.palette["void"]
      terminal.backgroundColor = activeMap.palette["void"]
      terminal.put(point: point, code: 0)
    }

    terminal.foregroundColor = activeMap.palette["lightgreen"]
    for posC in positionS.all where self.can(entity: player, see: posC.point) {
      terminal.put(point: posC.point, code: CP437.AT)
    }
  }

  var size: BLSize { return activeMap.size }
  var layerIndices: [Int] { return activeMap.layerIndices }
}
