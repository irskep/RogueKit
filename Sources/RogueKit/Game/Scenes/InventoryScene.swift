//
//  InventoryScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


extension Scene {
  var gameDirector: SteveRLDirector { return director as! SteveRLDirector }
}


class InventoryScene: Scene, WorldDrawingSceneProtocol {
  let worldModel: WorldModel
  let resources: ResourceCollectionProtocol
  var inspectedEntity: Entity? { return nil }
  let returnToScene: Scene
  var state: State

  enum State {
    case willOpenMenu
    case willEquip
    case willDrop
    case menuIsOpen(Int)

    var title: String {
      switch self {
      case .willOpenMenu, .menuIsOpen(_): return "Inventory (broken)"
      case .willEquip: return "Equip"
      case .willDrop: return "Drop"
      }
    }
  }

  lazy var myDefaultKeys: [BLInt] = {
    return SimpleMenu.defaultKeys
      .filter({ ![
        self.gameDirector.config.keyInventoryOpen,
        self.gameDirector.config.keyDrop,
        self.gameDirector.config.keyEquip,
        ].contains($0)
      })
  }()

  lazy var menu: SimpleMenu = {
    return SimpleMenu(
      rect: BLRect(x: 0, y: 0, w: 0, h: 0),
      items: (0..<worldModel.playerInventory.count)
        .map({
          let index = $0
          let key = self.myDefaultKeys[$0]
          let e = self.worldModel.playerInventory[$0]
          var label = self.worldModel.nameS[e]?.name ?? "NOT FOUND"
          if e == self.worldModel.playerWeaponC?.entity {
            label += " (wielded)"
          }
          return (key, label, { self.selectItem(index: index, entity: e) })
        }))
  }()

  init(
    resources: ResourceCollectionProtocol,
    worldModel: WorldModel,
    returnToScene: Scene,
    state: State)
  {
    self.worldModel = worldModel
    self.resources = resources
    self.returnToScene = returnToScene
    self.state = state
  }

  override func update(terminal: BLTerminalInterface) {
    self.drawWorld(in: terminal)

    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    menu.rect = BLRect(
      x: terminal.state(BLConstant.WIDTH) / 2 - 20,
      y: 10,
      w: 40,
      h: 2)
    menu.draw(in: terminal)

    terminal.print(
      rect: BLRect(
        origin: menu.rect.origin - BLPoint(x: 0, y: 1),
        size: BLSize(w: menu.rect.w, h: 1)),
      align: BLConstant.ALIGN_CENTER,
      string: "\(state.title):")

    terminal.foregroundColor = resources.defaultPalette["ui_accent"]
    DrawUtils.drawLineVertical(
      in: terminal,
      origin: menu.rect.origin + BLPoint(x: -1, y: -1),
      length: menu.rect.size.h + 1)
    DrawUtils.drawLineVertical(
      in: terminal,
      origin: menu.rect.origin + BLPoint(x: menu.rect.size.w + 1, y: -1),
      length: menu.rect.size.h + 1)

    terminal.refresh()

    if terminal.hasInput {
      let config = gameDirector.config
      let char = terminal.read()
      if char == config.keyMenu || char == config.keyInventoryOpen {
        director?.transition(to: returnToScene)
      } else {
        _ = menu.handle(char: char)
      }
    }
  }

  func selectItem(index: Int, entity: Entity) {
    switch state {
    case .willOpenMenu:
      self.state = .menuIsOpen(entity)
    case .willDrop:
      worldModel.drop(item: entity, fromInventoryOf: worldModel.player)
      exitState()
    case .willEquip:
      // 1. If item is a weapon and player wields a weapon, unwield the weapon.
      // 2. If item is a weapon and not wielded, wield it.
      // 3. If item is equipment and player has equipment in that slot, unequip that.
      // 4. If item is equipment and not equipped, equip it.

      if worldModel.playerWeaponC?.entity == entity {
        worldModel.unwield(weaponEntity: entity, on: worldModel.player)
      } else if let wieldedEntity = worldModel.playerWeaponC?.entity {
        worldModel.unwield(weaponEntity: wieldedEntity, on: worldModel.player)
        worldModel.wield(weaponEntity: entity, on: worldModel.player)
      } else {
        worldModel.wield(weaponEntity: entity, on: worldModel.player)
      }

      exitState()
    case .menuIsOpen(_):
      fatalError("Shouldn't be possible")
    }
  }

  func exitState() {
    // TODO: close menu if open?
    director?.transition(to: returnToScene)
  }
}
