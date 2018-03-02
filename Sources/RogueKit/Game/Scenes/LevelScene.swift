//
//  LevelScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


class LevelScene: Scene {
  let worldModel: WorldModel
  let resources: ResourceCollection

  var isDirty = false

  init(resources: ResourceCollection, worldModel: WorldModel) {
    self.worldModel = worldModel
    self.resources = resources
  }

  override func update(terminal: BLTerminalInterface) {
    isDirty = true
    if terminal.hasInput, let config = (director as? SteveRLDirector)?.config {
      switch terminal.read() {
      case config.keyLeft: worldModel.movePlayer(by: BLPoint(x: -1, y: 0))
      case config.keyRight: worldModel.movePlayer(by: BLPoint(x: 1, y: 0))
      case config.keyUp: worldModel.movePlayer(by: BLPoint(x: 0, y: -1))
      case config.keyDown: worldModel.movePlayer(by: BLPoint(x: 0, y: 1))
      case config.keyDebugLeft:
        director?.transition(to: LoadScene(rngStore: RandomSeedStore(seed: worldModel.rngStore.seed - 1), resources: resources, id: "basic"))
      case config.keyDebugRight:
        director?.transition(to: LoadScene(rngStore: RandomSeedStore(seed: worldModel.rngStore.seed + 1), resources: resources, id: "basic"))
      case BLConstant.CLOSE:
        director?.quit()
      default:
        isDirty = false
      }
    }

    if isDirty {
      terminal.layer = 0
      terminal.clear()
      worldModel.draw(in: terminal, at: BLPoint.zero)
      terminal.refresh()
    }
  }
}
