//
//  WorldDrawingSceneProtocol.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal

let MENU_W: BLInt = 26


private extension StatBucket {
  var description: String { return """
      HP: \(Int(hp))
      Fatigue: \(Int(fatigue))
      Reflex: \(Int(reflex))
      Strength: \(Int(strength))
      """.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
}


protocol WorldDrawingSceneProtocol {
  var director: Director? { get }
  var resources: ResourceCollectionProtocol { get }
  var worldModel: WorldModel { get }
  var inspectedEntity: Entity? { get }
}

extension WorldDrawingSceneProtocol {
  func drawWorld(in terminal: BLTerminalInterface) {
    let config = (director as! SteveRLDirector).config
    terminal.layer = 0
    terminal.backgroundColor = resources.defaultPalette["void"]
    terminal.clear()
    worldModel.draw(in: terminal, at: BLPoint.zero)

    terminal.foregroundColor = resources.defaultPalette["ui_text"]

    let keyString = [
      (config.keyEquip, "[un]wield/[un]equip"),
      (config.keyDrop, "drop"),
      ].map({
        "(\(BLConstant.label(for: $0.0)!)) \($0.1)"
      }).joined(separator: " ")

    terminal.print(
      point: BLPoint(x: 1, y: terminal.height - 2),
      string: keyString)

    let menuCtx = terminal.transform(offset: BLPoint(x: terminal.width - MENU_W, y: 0))

    var strings = ["Stats:"]
    if let myStatsString = worldModel.statsS[worldModel.player]?.currentStats.description {
      strings.append(myStatsString)
    }
    if let weaponDef = worldModel.weapon(wieldedBy: worldModel.player) {
      strings.append(contentsOf: ["", "Wielding: \(weaponDef.name)", "(\(weaponDef.description))"])
    }
    let s = strings.joined(separator: "\n")
    let stringSize = terminal.measure(
      size: BLSize(w: MENU_W - 2, h: 1000),
      align: BLConstant.ALIGN_LEFT,
      string: s)
    menuCtx.print(
      rect: BLRect(x: 1, y: 1, w: stringSize.w, h: stringSize.h),
      align: BLConstant.ALIGN_LEFT,
      string: strings.joined(separator: "\n"))


    if let inspectedEntity = inspectedEntity,
      let nameC = worldModel.nameS[inspectedEntity]
    {
      var strings = [nameC.name, "", nameC.description]
      if let statsString = worldModel.statsS[inspectedEntity]?.currentStats.description {
        strings.append(contentsOf: ["", statsString])
      }
      if let weaponDef = worldModel.weapon(wieldedBy: inspectedEntity) {
        strings.append(contentsOf: ["", "Wielding: \(weaponDef.name)"])
      }
      let string = strings.joined(separator: "\n")
      let stringSize = terminal.measure(
        size: BLSize(w: MENU_W - 2, h: 1000),
        align: BLConstant.ALIGN_LEFT,
        string: string)
      menuCtx.print(
        rect: BLRect(
          x: 1,
          y: terminal.height - stringSize.h - 1,
          w: MENU_W - 2,
          h: stringSize.h),
        align: BLConstant.ALIGN_LEFT,
        string: string)
    }

    menuCtx.foregroundColor = resources.defaultPalette["ui_accent"]
    DrawUtils.drawLineVertical(in: menuCtx, origin: BLPoint.zero, length: terminal.height)
  }
}
