//
//  WinScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/8/18.
//

import Foundation
import BearLibTerminal

private let TITLE = """
                                                                  ___
                                                 .-.             (   )
 ___  ___    .--.    ___  ___     ___  ___  ___ ( __)  ___ .-.    | |
(   )(   )  /    \\  (   )(   )   (   )(   )(   )(''") (   )   \\   | |
 | |  | |  |  .-. ;  | |  | |     | |  | |  | |  | |   |  .-. .   | |
 | |  | |  | |  | |  | |  | |     | |  | |  | |  | |   | |  | |   | |
 | '  | |  | |  | |  | |  | |     | |  | |  | |  | |   | |  | |   | |
 '  `-' |  | |  | |  | |  | |     | |  | |  | |  | |   | |  | |   | |
  `.__. |  | '  | |  | |  ; '     | |  ; '  | |  | |   | |  | |   |_|
  ___ | |  '  `-' /  ' `-'  /     ' `-'   `-' '  | |   | |  | |   .-.
 (   )' |   `.__.'    '.__.'       '.__.'.__.'  (___) (___)(___) (   )
  ; `-' '                                                         '-'
   .__.'
"""

private let INTRO = """
You win!

Press Esc or Enter to continue.
"""


class WinScene: Scene {
  let resources: ResourceCollectionProtocol

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  lazy var headshot: REXPaintImage? = { return resources.rexPaintImage(named: "hv_lose") }()

  override func update(terminal: BLTerminalInterface) {
    terminal.backgroundColor = resources.defaultPalette["ui_bg"]
    terminal.clear()

    if let headshot = headshot {
      headshot.draw(in: terminal, at: BLPoint(x: terminal.width / 2 - headshot.width / 2, y: 0))
    }

    terminal.backgroundColor = resources.defaultPalette["ui_bg"]
    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    terminal.print(
      rect: BLRect(x: terminal.width / 4, y: terminal.height - 4, w: terminal.width / 2, h: 1000),
      align: BLConstant.ALIGN_CENTER,
      string: INTRO.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))

    terminal.foregroundColor = resources.defaultPalette["green"]
    let rect = BLRect(x: 0, y: terminal.height / 4 * 3 - 3, w: terminal.state(BLConstant.WIDTH), h: 10)
    _ = drawCenteredString(terminal, rect, TITLE)

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

