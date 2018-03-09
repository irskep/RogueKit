//
//  TextScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/9/18.
//

import Foundation
import BearLibTerminal


class TextScene: Scene, WorldDrawingSceneProtocol {
  let worldModel: WorldModel
  let resources: ResourceCollectionProtocol
  var inspectedEntity: Entity? { return nil }
  let returnToScene: Scene
  let text: String

  init(
    resources: ResourceCollectionProtocol,
    worldModel: WorldModel,
    returnToScene: Scene,
    text: String)
  {
    self.worldModel = worldModel
    self.resources = resources
    self.returnToScene = returnToScene
    self.text = text.replacingOccurrences(of: "\\n", with: "\n")
  }

  override func willEnter(with director: Director) {
    super.willEnter(with: director)
    worldModel.activeMap.palette.apply(to: BLTerminal.main)  // cheat
  }

  override func update(terminal: BLTerminalInterface) {
    self.drawWorld(in: terminal)

    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    let w: BLInt = 80
    let h = terminal.measure(size: BLSize(w: w, h: 1000),
                             align: BLConstant.ALIGN_LEFT, string: text).h
    let uiRect = BLRect(
      x: terminal.state(BLConstant.WIDTH) / 2 - w / 2,
      y: terminal.state(BLConstant.HEIGHT) / 2 - h / 2,
      w: w,
      h: h + 2)
    terminal.clear(area: uiRect)
    terminal.foregroundColor = resources.defaultPalette["ui_accent"]
    DrawUtils.drawBox(in: terminal, rect: uiRect)

    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    terminal.print(rect: uiRect.inset(byX1: 1, y1: 1, x2: 1, y2: 1), align: BLConstant.ALIGN_LEFT, string: text)

    terminal.refresh()

    let config = gameDirector.config
    switch terminal.read() {
    case config.keyMenu, config.keyWait, config.keyRangedFire:
      director?.transition(to: returnToScene)
    default: break
    }
  }
}
