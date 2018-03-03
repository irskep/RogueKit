//
//  LoadScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


class LoadScene: Scene {
  let worldModel: WorldModel
  let id: String
  let resources: ResourceCollection

  var terminal: BLTerminalInterface? { return director?.terminal }

  init(worldModel: WorldModel, resources: ResourceCollection, id: String) {
    self.worldModel = worldModel
    self.id = id
    self.resources = resources
  }

  var nextScene: Scene?

  override func update(terminal: BLTerminalInterface) {
    print("Loading map \(id) using generator \(worldModel.mapDefinitions[id]!.generatorId)")
    guard worldModel.maps[self.id] == nil else {
      worldModel.travel(to: self.id)
      self.director?.transition(to: LevelScene(resources: self.resources, worldModel: self.worldModel))
      return
    }

    let rng = worldModel.rngStore[id]
    let reader = GeneratorReader(resources: resources)
    try! reader.run(id: worldModel.mapDefinitions[id]!.generatorId, rng: rng) {
      gen, status, result in
      print(status)

      guard self.director?.activeScene === self else { return }

      terminal.clear()
      terminal.layer = 0
      gen.draw(in: terminal, at: BLPoint.zero)
      terminal.layer = 2
      gen.debugDistanceField?.draw(in: terminal, at: BLPoint.zero)
      terminal.refresh()

      if result != nil {
        let levelMap = try LevelMap(
          definition: worldModel.mapDefinitions[self.id]!,
          size: gen.cells.size,
          paletteName: "default",
          resources: resources,
          terminal: terminal,
          generator: gen)

        var floorsWithMargins = Array(levelMap.floorsWithMargins)
        rng.shuffleInPlace(&floorsWithMargins)
        let entrance = floorsWithMargins[0]
        let exit = floorsWithMargins[1]
        let playerStart = rng.choice(Array(floorsWithMargins[0]
          .getNeighbors(bounds: BLRect(size: levelMap.size), diagonals: false)))

        let blacklist = [entrance, exit]
        var floors = levelMap.floors.filter({ !blacklist.contains($0) })
        rng.shuffleInPlace(&floors)
        
        levelMap.pointsOfInterest = [
          PointOfInterest(kind: "playerStart", point: playerStart),
          PointOfInterest(kind: "enemy", point: floors[0]),
          PointOfInterest(kind: "item", point: floors[1]),
          PointOfInterest(kind: "item", point: floors[2]),
          PointOfInterest(kind: "item", point: floors[3]),
        ]
        if levelMap.definition.exits["previous"] != nil {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "entrance", point: entrance))
        }
        if levelMap.definition.exits["next"] != nil {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "exit", point: exit))
        }

        levelMap.isPopulated = true

        self.worldModel.maps[self.id] = levelMap
        self.worldModel.travel(to: self.id)
        self.worldModel.applyPOIs()
        self.director?.transition(to: LevelScene(resources: self.resources, worldModel: self.worldModel))
      }
    }
  }
}
