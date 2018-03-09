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
    terminal.layer = 0
    terminal.backgroundColor = resources.defaultPalette["void"]
    terminal.clear()
    worldModel.draw(in: terminal, at: BLPoint.zero)

    terminal.foregroundColor = resources.defaultPalette["ui_text_dim"]
    terminal.print(
      point: BLPoint(x: 1, y: terminal.height - 1),
      string: "Press ? for help. Keys are: arrows, tab, enter, E(quip), D(rop)")


    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    let menuCtx = terminal.transform(offset: BLPoint(x: terminal.width - MENU_W, y: 0))

    var s = StringUtils.describe(
      entity: worldModel.player, in: worldModel, showName: false,
      showWeaponDescription: true,
      compareToEquipmentOn: nil)
    if worldModel.gameHasntEnded, let desc = worldModel.activeMap.descriptionOfRoom(
        coveringCellAt: worldModel.playerPos) {
      s += "\n\n" + "[color=ui_text_dim]Current room:\n[color=ui_text]" + desc
    }
    if worldModel.debugFlags["invincible"] == 1 {
      s += "\n\nINVINCIBLE"
    }

    let stringSize = terminal.measure(
      size: BLSize(w: MENU_W - 1, h: 1000),
      align: BLConstant.ALIGN_LEFT,
      string: s)
    menuCtx.print(
      rect: BLRect(x: 1, y: 0, w: stringSize.w, h: stringSize.h),
      align: BLConstant.ALIGN_LEFT,
      string: s)
    menuCtx.foregroundColor = resources.defaultPalette["ui_accent"]
    DrawUtils.drawLineVertical(in: menuCtx, origin: BLPoint.zero, length: terminal.height)


    terminal.foregroundColor = terminal.getColor(name: "ui_text")
    let y = worldModel.activeMap.cells.size.h
    let h = terminal.height - 2 - y
    let w = terminal.width - MENU_W
    var messages = worldModel.messageLog
    if messages.count > h {
      messages = Array(messages.dropFirst(messages.count - Int(h)))
    }
    terminal.print(
      rect: BLRect(x: 1, y: y, w: w, h: h),
      align: BLConstant.ALIGN_LEFT,
      string: messages.joined(separator: "\n"))

    if let inspectedEntity = inspectedEntity,
      let point = worldModel.positionS[inspectedEntity]?.point,
      worldModel.nameS[inspectedEntity] != nil
    {
      let string = StringUtils.describe(
        entity: inspectedEntity, in: worldModel, showName: true,
        showWeaponDescription: false, compareToEquipmentOn: worldModel.player)

      let menuOrigin: BLPoint
      if point.x < worldModel.activeMap.size.w / 2 {
        menuOrigin = BLPoint(x: terminal.width - MENU_W * 2, y: 0)
      } else {
        menuOrigin = BLPoint.zero
      }
      let menuRect = BLRect(origin: menuOrigin, size: BLSize(w: MENU_W, h: 50))
      terminal.clear(area: menuRect)
      terminal.foregroundColor = resources.defaultPalette["ui_accent"]
      DrawUtils.drawBox(in: terminal, rect: menuRect)
      terminal.foregroundColor = resources.defaultPalette["ui_text"]
      terminal.print(
        rect: menuRect.inset(byX1: 1, y1: 1, x2: 1, y2: 1),
        align: BLConstant.ALIGN_LEFT,
        string: string)
    }
  }
}
