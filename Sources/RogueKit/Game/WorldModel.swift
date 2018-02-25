//
//  WorldModel.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/21/18.
//

import Foundation
import BearLibTerminal


typealias Entity = Int


class WorldModel: Codable {
  let map: LevelMap
  let random: RKRNGProtocol

  lazy var floors: [BLPoint] = {
    var points = [BLPoint]()
    for point in BLRect(size: map.size) {
      if map.cells[point]?.terrain == 1 {
        points.append(point)
      }
    }
    return points
  }()

  var mapMemory = Set<BLPoint>()

  var positionS = PositionS()
  var sightS = SightS()
  var fovS = FOVS()

  var player: Entity = 1
  var povEntity: Entity { return player }

  enum CodingKeys: String, CodingKey {
    case map
    case random
    case mapMemory
    case positionS
    case sightS
    case fovS
    case player
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    map = try values.decode(LevelMap.self, forKey: .map)
    if #available(OSX 10.11, *) {
      random = try values.decode(RKGameKitRNG.self, forKey: .random)
    } else {
      random = try values.decode(RKRNG.self, forKey: .random)
    }
    mapMemory = try values.decode(Set<BLPoint>.self, forKey: .mapMemory)
    positionS = try values.decode(PositionS.self, forKey: .positionS)
    sightS = try values.decode(SightS.self, forKey: .sightS)
    fovS = try values.decode(FOVS.self, forKey: .fovS)
    player = try values.decode(Entity.self, forKey: .player)

  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(map, forKey: .map)
    if let random = random as? RKRNG {
      try container.encode(random, forKey: .random)
    } else if #available(OSX 10.11, *), let random = random as? RKGameKitRNG {
      try container.encode(random, forKey: .random)
    }
    try container.encode(mapMemory, forKey: .mapMemory)
    try container.encode(positionS, forKey: .positionS)
    try container.encode(sightS, forKey: .sightS)
    try container.encode(fovS, forKey: .fovS)
    try container.encode(player, forKey: .player)
  }

  init(random: RKRNGProtocol, map: LevelMap) {
    self.random = random
    self.map = map

    let playerPoint = random.choice(floors)
    sightS.add(entity: player, component: SightC(entity: player))
    positionS.add(entity: player, component: PositionC(entity: player, point: playerPoint))
    fovS.add(entity: player, component: FOVC(entity: player))

    self.playerDidTakeAction()
  }

  subscript(index: Int) -> PositionC? { return positionS[index] }
  subscript(index: Int) -> SightC? { return sightS[index] }

  func playerDidTakeAction() {
    if let fovC = fovS[player] {
      fovC.reset()
      mapMemory.formUnion(fovC.getFovCache(map: map, positionS: positionS, sightS: sightS))
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
    return map.getIsPassable(entity: entity, point: point)
  }

  func may(entity: Entity, interactAt point: BLPoint) -> Bool {
    guard let cell = map.cells[point] else { return false }
    return self.map.interactions[cell.feature] != nil
  }

  func interact(entity: Entity, with point: BLPoint) {
    guard let cell = map.cells[point] else { return }
    if let interaction = map.interactions[cell.feature] {
      run(interaction: interaction, entity: entity, point: point)
    }
  }

  func run(interaction: Interaction, entity: Entity, point: BLPoint) {
    let items = interaction.script.split(separator: " ")
    switch items[0] {
    case "replace_feature_with":
      let targetName = String(items[1])
      let targetId = map.featureIdsByName[targetName]!
      map.cells[point]?.feature = targetId
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
    let fovCache = fovS[player]?.getFovCache(map: map, positionS: positionS, sightS: sightS) ?? Set()
    if fovCache.contains(point) {
      map.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: true)
    } else if mapMemory.contains(point) {
      map.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: false)
    } else {
      terminal.foregroundColor = map.palette["void"]
      terminal.backgroundColor = map.palette["void"]
      terminal.put(point: point, code: 0)
    }

    // TODO: use a cache
    terminal.foregroundColor = map.palette["lightgreen"]
    for posC in positionS.all where fovCache.contains(posC.point) {
      terminal.put(point: posC.point, code: CP437.AT)
    }
  }

  var size: BLSize { return map.size }
  var layerIndices: [Int] { return map.layerIndices }
}
