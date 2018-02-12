//
//  WorldModel.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/21/18.
//

import Foundation
import BearLibTerminal


typealias Entity = Int


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

  var mapMemory = Set<BLPoint>()

  let positionS = PositionS()
  let sightS = SightS()
  let fovS = FOVS()

  let player: Entity = 1
  var povEntity: Entity { return player }

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
      mapMemory.formUnion(fovC.getFovCache(map: map, positionS: positionS, sightS: sightS))
      fovC.reset()
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
    return self.map.interactions[map.cells[point].feature] != nil
  }

  func interact(entity: Entity, with point: BLPoint) {
    if let interaction = map.interactions[map.cells[point].feature] {
      run(interaction: interaction, entity: entity, point: point)
    }
  }

  func run(interaction: Interaction, entity: Entity, point: BLPoint) {
    let items = interaction.script.split(separator: " ")
    switch items[0] {
    case "replace_feature_with":
      let targetName = String(items[1])
      let targetId = map.featureIdsByName[targetName]!
      map.cells[point].feature = targetId
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
