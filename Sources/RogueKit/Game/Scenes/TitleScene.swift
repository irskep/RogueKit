//
//  TitleScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal

private let TITLE = """
██▄   █▄▄▄▄       ▄  █ ██   █    █     ▄███▄   █▄▄▄▄    ▄   ████▄ █▄▄▄▄ ██▄   ▄███▄      ▄
█  █  █  ▄▀      █   █ █ █  █    █     █▀   ▀  █  ▄▀     █  █   █ █  ▄▀ █  █  █▀   ▀      █
█   █ █▀▀▌       ██▀▀█ █▄▄█ █    █     ██▄▄    █▀▀▌ █     █ █   █ █▀▀▌  █   █ ██▄▄    ██   █
█  █  █  █       █   █ █  █ ███▄ ███▄  █▄   ▄▀ █  █  █    █ ▀████ █  █  █  █  █▄   ▄▀ █ █  █
███▀    █  ██       █     █     ▀    ▀ ▀███▀     █    █  █          █   ███▀  ▀███▀   █  █ █
       ▀           ▀     █                      ▀      ▐█          ▀                  █   ██
                        ▀                              ▐
"""

private let INTRO = """
You, a retail store employee, were captured by the mad scientist Dr. Hallervorden. For a year, you have been a test subject for his demented experiments. You are stronger and more capable than when you came in, but nothing remains of your mind but rage.

This morning, your cell door swung open on its own. It is time to escape!
"""

var seedOverride: UInt64? = nil

func drawCenteredString(_ terminal: BLTerminalInterface, _ box: BLRect, _ s: String) -> BLSize {
  let stringSize = terminal.measure(string: s)
  let x = box.x + box.w / 2 - stringSize.w / 2
  let y = box.y + box.h / 2 - stringSize.h / 2
  return terminal.print(point: BLPoint(x: x, y: y), string: s)
}


class TitleScene: Scene {
  let resources: ResourceCollectionProtocol
  lazy var menu: SimpleMenu = {
    if let gameURL = URLs.gameURL, FileManager.default.fileExists(atPath: gameURL.path) {
      return SimpleMenu(rect: BLRect(x: 0, y: 0, w: 0, h: 0), items: [
        (BLConstant.A, "Start Game", { [weak self] in self?.actionStartGame() }),
        (BLConstant.B, "Load Game", { [weak self] in self?.actionLoadGame() }),
        (BLConstant.Q, "Quit", { [weak self] in self?.actionQuit() }),
        ])
    } else {
      return SimpleMenu(rect: BLRect(x: 0, y: 0, w: 0, h: 0), items: [
        (BLConstant.A, "Start Game", { [weak self] in self?.actionStartGame() }),
        (BLConstant.Q, "Quit", { [weak self] in self?.actionQuit() }),
        ])
    }
  }()

  lazy var headshot: REXPaintImage? = { return resources.rexPaintImage(named: "hallervorden_title") }()

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  override func update(terminal: BLTerminalInterface) {
    terminal.backgroundColor = resources.defaultPalette["ui_bg"]
    terminal.clear()

    if let headshot = headshot {
      headshot.draw(in: terminal, at: BLPoint.zero)
    }

    terminal.foregroundColor = resources.defaultPalette["green"]
    let rect = BLRect(x: 0, y: 0, w: terminal.state(BLConstant.WIDTH), h: 10)
    _ = drawCenteredString(terminal, rect, TITLE)

    terminal.foregroundColor = resources.defaultPalette["ui_text"]
    menu.rect = BLRect(
      x: terminal.width / 2 - 10,
      y: terminal.height * 3 / 4 - 1,
      w: 20,
      h: 2)
    menu.draw(in: terminal)

//    terminal.print(
//      rect: BLRect(x: terminal.width / 4, y: terminal.height / 3, w: terminal.width / 2, h: 1000),
//      align: BLConstant.ALIGN_LEFT,
//      string: INTRO.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))

    terminal.refresh()

    if terminal.hasInput {
      let char = terminal.read()
      _ = menu.handle(char: char)
    }
  }

  func actionStartGame() {
    var t: timeval = timeval()
    gettimeofday(&t, nil)
    let seed = Int64(t.tv_sec * 1000) + Int64(t.tv_usec / 1000)
    print("SEED:", seedOverride ?? seed)
    let worldModel = WorldModel(
      rngStore: RandomSeedStore(seed: seedOverride ?? UInt64(seed)),
      resources: resources,
      mapDefinitions: resources.csvDB.mapDefinitions,
      activeMapId: resources.csvDB.mapDefinitions.first!.id)
    director?.transition(to: LoadScene(worldModel: worldModel, resources: resources, id: "1"))
  }

  func actionLoadGame() {
    guard let gameURL = URLs.gameURL, FileManager.default.fileExists(atPath: gameURL.path) else {
      return
    }
    do {
      let data: Data = try Data(contentsOf: gameURL)
      let world = try JSONDecoder().decode(WorldModel.self, from: data)
      world.resources = resources
      director?.transition(to: LevelScene(resources: resources, worldModel: world))
    } catch let error {
      print(error)
      NSLog("Unable to load saved game")
    }
  }

  func actionQuit() {
    director?.quit()
  }
}

