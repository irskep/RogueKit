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
  func draw(in terminal: BLTerminalInterface, at point: BLPoint) {
    let ctx = terminal.transform(offset: point)
    ctx.print(point: BLPoint(x: 0, y: 0), string: """
      HP: \(Int(hp))
      Fatigue: \(Int(fatigue))
      Reflex: \(Int(reflex))
      Strength: \(Int(strength))
      """.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
  }
}


protocol WorldDrawingSceneProtocol {
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

    let menuCtx = terminal.transform(offset: BLPoint(x: terminal.width - MENU_W, y: 0))
    menuCtx.foregroundColor = resources.defaultPalette["ui_text"]
    menuCtx.print(point: BLPoint(x: 1, y: 1), string: "Stats:")
    worldModel.statsS[worldModel.player]?.currentStats.draw(
      in: menuCtx,
      at: BLPoint(x: 1, y: 2))

    if let inspectedEntity = inspectedEntity {
      if let nameC = worldModel.nameS[inspectedEntity] {
        menuCtx.print(point: BLPoint(x: 1, y: terminal.height - 6), string: nameC.name)
      }
      worldModel.statsS[inspectedEntity]?.currentStats.draw(
        in: menuCtx,
        at: BLPoint(x: 1, y: terminal.height - 5))
    }

    menuCtx.foregroundColor = resources.defaultPalette["ui_accent"]
    DrawUtils.drawLineVertical(in: menuCtx, origin: BLPoint.zero, length: terminal.height)
  }
}
