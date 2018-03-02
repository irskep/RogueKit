//
//  LoadScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


class LoadScene: Scene {
  let rngStore: RandomSeedStore
  let id: String
  let resources: ResourceCollection

  var terminal: BLTerminalInterface? { return director?.terminal }

  init(rngStore: RandomSeedStore, resources: ResourceCollection, id: String) {
    self.rngStore = rngStore
    self.id = id
    self.resources = resources
  }

  var nextScene: Scene?

  override func update(terminal: BLTerminalInterface) {
    if let nextScene = nextScene {
      director?.transition(to: nextScene)
      return
    }

    let rng = rngStore[id]
    let reader = GeneratorReader(resources: resources)
    try! reader.run(id: id, rng: rng) {
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
          id: "\(rngStore.seed)",
          size: gen.cells.size,
          paletteName: "default",
          resources: resources,
          terminal: terminal,
          generator: gen)
        let world = WorldModel(rngStore: rngStore, map: levelMap)
        self.nextScene = LevelScene(resources: self.resources, worldModel: world)
      }
    }
  }
}
