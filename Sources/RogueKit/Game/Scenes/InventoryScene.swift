//
//  InventoryScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


class InventoryScene: Scene {
  let worldModel: WorldModel
  let resources: ResourceCollection

  lazy var menu: SimpleMenu = {
    return SimpleMenu(
      rect: BLRect(x: 0, y: 0, w: 0, h: 0),
      items: (0..<worldModel.playerInventory.count)
        .map({
          let key = SimpleMenu.defaultKeys[$0]
          let e = worldModel.playerInventory[$0]
          return (
            key,
            self.worldModel.collectibleS[e]?.title ?? "NOT FOUND",
            { self.selectItem(entity: e) })
        }))
  }()

  init(resources: ResourceCollection, worldModel: WorldModel) {
    self.worldModel = worldModel
    self.resources = resources
  }

  override func update(terminal: BLTerminalInterface) {
    terminal.layer = 0
    terminal.clear()
    worldModel.draw(in: terminal, at: BLPoint.zero)

    menu.rect = BLRect(
      x: terminal.state(BLConstant.WIDTH) / 2 - 10,
      y: 10,
      w: 40,
      h: 2)
    menu.draw(in: terminal)
    terminal.print(point: menu.rect.origin + BLPoint(x: 0, y: -1), string: "Inventory:")

    terminal.refresh()

    if terminal.hasInput, let config = (director as? SteveRLDirector)?.config {
      let char = terminal.read()
      if char == config.keyMenu {
        director?.transition(to: LevelScene(resources: resources, worldModel: worldModel))
      } else {
        _ = menu.handle(char: char)
      }
    }
  }

  func selectItem(entity: Entity) {
    director?.transition(to: LevelScene(resources: resources, worldModel: worldModel))
  }
}
