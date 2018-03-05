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


extension String {
  var bltEscaped: String { return self
    .replacingOccurrences(of: "]", with: "]]")
    .replacingOccurrences(of: "[", with: "[[")
  }
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
      case .willEquip: return "Equip/Unequip"
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
          if let armorC = self.worldModel.armorS[e] {
            label = "\(CP437.string(for: armorC.armorDefinition.char).bltEscaped) " + label
          }
          print(label)
          if let weaponC = self.worldModel.weaponS[e] {
            label = "\(CP437.string(for: weaponC.weaponDefinition.char).bltEscaped) " + label
          }
          if e == self.worldModel.playerWeaponC?.entity {
            label += " (wielded)"
          }
          if self.worldModel.equipmentS[self.worldModel.player]!.isWearing(e) {
            label += "(\(self.worldModel.armorS[e]!.armorDefinition.slot))"
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
    let uiRect = BLRect(
      x: terminal.state(BLConstant.WIDTH) / 2 - 20,
      y: terminal.state(BLConstant.HEIGHT) / 2 - 15,
      w: 40,
      h: 30)
    menu.rect = uiRect.inset(byX1: 1, y1: 3, x2: 1, y2: 1)
    terminal.clear(area: uiRect)
    terminal.foregroundColor = resources.defaultPalette["ui_accent"]
    DrawUtils.drawBox(in: terminal, rect: uiRect)
    terminal.foregroundColor = resources.defaultPalette["ui_text"]

    menu.draw(in: terminal)

    terminal.print(
      rect: BLRect(
        origin: uiRect.origin + BLPoint(x: 1, y: 1),
        size: BLSize(w: uiRect.size.w - 2, h: 1)),
      align: BLConstant.ALIGN_CENTER,
      string: "\(state.title):")

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
      if worldModel.weaponS[entity] != nil {
        if worldModel.playerWeaponC?.entity == entity {
          worldModel.unwield(weaponEntity: entity, on: worldModel.player)
        } else {
          worldModel.wield(weaponEntity: entity, on: worldModel.player)
        }
      } else if let armorC = worldModel.armorS[entity] {
        let playerEquipmentC = worldModel.equipmentS[worldModel.player]!
        if playerEquipmentC.slots[armorC.armorDefinition.slot] == entity {
          playerEquipmentC.remove(armor: entity, on: armorC.armorDefinition.slot)
        } else {
          playerEquipmentC.put(armor: entity, on: armorC.armorDefinition.slot)
        }
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
