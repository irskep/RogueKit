//
//  LoseScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/5/18.
//

import Foundation
import BearLibTerminal

private let TITLE = """
  ▄▀  ██   █▀▄▀█ ▄███▄       ████▄     ▄   ▄███▄   █▄▄▄▄
▄▀    █ █  █ █ █ █▀   ▀      █   █      █  █▀   ▀  █  ▄▀
█ ▀▄  █▄▄█ █ ▄ █ ██▄▄        █   █ █     █ ██▄▄    █▀▀▌
█   █ █  █ █   █ █▄   ▄▀     ▀████  █    █ █▄   ▄▀ █  █
 ███     █    █  ▀███▀               █  █  ▀███▀     █
        █    ▀                        ▐█            ▀
       ▀                              ▐
"""

private let INTRO = """
You are dead.
"""


class LoseScene: Scene {
  let resources: ResourceCollectionProtocol

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  override func update(terminal: BLTerminalInterface) {
    terminal.backgroundColor = resources.defaultPalette["ui_bg"]
    terminal.clear()

    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    terminal.print(
      rect: BLRect(x: terminal.width / 4, y: terminal.height / 3, w: terminal.width / 2, h: 1000),
      align: BLConstant.ALIGN_LEFT,
      string: INTRO.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))

    terminal.foregroundColor = resources.defaultPalette["green"]
    let rect = BLRect(x: 0, y: 0, w: terminal.state(BLConstant.WIDTH), h: 10)
    drawCenteredString(terminal, rect, TITLE)

    terminal.refresh()

    if terminal.hasInput {
      switch terminal.read() {
      case BLConstant.ESCAPE, BLConstant.ENTER:
        director?.transition(to: TitleScene(resources: resources))
      default: break
      }
    }
  }
}

