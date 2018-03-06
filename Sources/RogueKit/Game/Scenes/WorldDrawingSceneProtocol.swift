//
//  WorldDrawingSceneProtocol.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal

let MENU_W: BLInt = 26


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

    var keyString = [
      (config.keyEquip, "[un]wield/[un]equip".bltEscaped),
      (config.keyDrop, "drop"),
      ].map({
        "(\(BLConstant.label(for: $0.0)!)) \($0.1)"
      }).joined(separator: " ")
    keyString += " (arrows) move and attack by bumping"
    keyString += "\n(tab) select enemies (enter) fire ranged weapon (space) wait"

    terminal.foregroundColor = resources.defaultPalette["ui_text_dim"]
    terminal.print(
      point: BLPoint(x: 1, y: terminal.height - 2),
      string: keyString)


    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    let menuCtx = terminal.transform(offset: BLPoint(x: terminal.width - MENU_W, y: 0))

    let s = StringUtils.describe(
      entity: worldModel.player, in: worldModel, showName: false, showWeaponDescription: true)
    let stringSize = terminal.measure(
      size: BLSize(w: MENU_W - 1, h: 1000),
      align: BLConstant.ALIGN_LEFT,
      string: s)
    menuCtx.print(
      rect: BLRect(x: 1, y: 0, w: stringSize.w, h: stringSize.h),
      align: BLConstant.ALIGN_LEFT,
      string: s)

    if let inspectedEntity = inspectedEntity, worldModel.nameS[inspectedEntity] != nil {
      let string = StringUtils.describe(
        entity: inspectedEntity, in: worldModel, showName: true, showWeaponDescription: false)
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
