//
//  HelpScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/8/18.
//

import Foundation
import BearLibTerminal

private let HELP: String = """
Dr. Hallervorden Help
=====================

Press ? to hide and show this screen.

MOVEMENT
--------

(arrows) Move
(space)  Wait a turn (recover HP and Fatigue)
(tab)    Inspect things you can see
(enter)  Move toward or attack the selected thing
(r)      Wait until you see an enemy or you're fully healed.
         There's no food clock, so there is no penalty for doing this.
(q)      Save and exit to the title screen

ITEMS
-----

(d) Drop an item from your inventory, and pick up the item on the ground, if
    there is one and it fits

Items are automatically picked up as you move, unless they won't fit in your inventory.

EQUIPMENT
---------

(e) Equip or unequip weapons and armor

You have one weapon slot and 3 armor slots (head, body, hands). Never mind about legs, they're not important.

COMBAT
------

(arrows)       Bump into enemies to attack them with MELEE weapons.
(tab, mouse)   Select an enemy for a ranged attack
(enter, click) Attack the selected enemy with your wielded ranged weapon
(s)            Reset your fatigue with a stim

Combat costs FATIGUE. If you get too fatigued, you lose a turn after fighting.

Some weapons (mostly ranged) have a COOLDOWN. While a weapon is cooling down,
you will attack with your fallback weapon, i.e. your fists.
"""


class HelpScene: Scene, WorldDrawingSceneProtocol {
  let worldModel: WorldModel
  let resources: ResourceCollectionProtocol
  var inspectedEntity: Entity? { return nil }
  let returnToScene: Scene

  init(
    resources: ResourceCollectionProtocol,
    worldModel: WorldModel,
    returnToScene: Scene)
  {
    self.worldModel = worldModel
    self.resources = resources
    self.returnToScene = returnToScene
  }

  override func update(terminal: BLTerminalInterface) {
    self.drawWorld(in: terminal)

    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    let w: BLInt = 80
    let h = terminal.measure(size: BLSize(w: w, h: 1000), align: BLConstant.ALIGN_LEFT, string: HELP).h
    let uiRect = BLRect(
      x: terminal.state(BLConstant.WIDTH) / 2 - w / 2,
      y: terminal.state(BLConstant.HEIGHT) / 2 - h / 2,
      w: w,
      h: h)
    terminal.clear(area: uiRect)
    terminal.foregroundColor = resources.defaultPalette["ui_accent"]
    DrawUtils.drawBox(in: terminal, rect: uiRect)
    terminal.foregroundColor = resources.defaultPalette["ui_text"]

    terminal.print(rect: uiRect.inset(byX1: 1, y1: 1, x2: 1, y2: 1), align: BLConstant.ALIGN_LEFT, string: HELP)

    terminal.refresh()

    if terminal.hasInput {
      let config = gameDirector.config
      let char = terminal.read()
      if char == config.keyMenu || (char == config.keyHelp && terminal.check(BLConstant.SHIFT)) {
        director?.transition(to: returnToScene)
      }
    }
  }
}
