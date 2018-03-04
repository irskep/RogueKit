//
//  TitleScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal

let TITLE = """
██▄   █▄▄▄▄       ▄  █ ██   █    █     ▄███▄   █▄▄▄▄    ▄   ████▄ █▄▄▄▄ ██▄   ▄███▄      ▄
█  █  █  ▄▀      █   █ █ █  █    █     █▀   ▀  █  ▄▀     █  █   █ █  ▄▀ █  █  █▀   ▀      █
█   █ █▀▀▌       ██▀▀█ █▄▄█ █    █     ██▄▄    █▀▀▌ █     █ █   █ █▀▀▌  █   █ ██▄▄    ██   █
█  █  █  █       █   █ █  █ ███▄ ███▄  █▄   ▄▀ █  █  █    █ ▀████ █  █  █  █  █▄   ▄▀ █ █  █
███▀    █  ██       █     █     ▀    ▀ ▀███▀     █    █  █          █   ███▀  ▀███▀   █  █ █
       ▀           ▀     █                      ▀      ▐█          ▀                  █   ██
                        ▀                              ▐
"""


func drawCenteredString(_ terminal: BLTerminalInterface, _ box: BLRect, _ s: String) {
  let stringSize = terminal.measure(string: s)
  let x = box.x + box.w / 2 - stringSize.w / 2
  let y = box.y + box.h / 2 - stringSize.h / 2
  terminal.print(point: BLPoint(x: x, y: y), string: s)
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

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  override func update(terminal: BLTerminalInterface) {
    terminal.backgroundColor = resources.defaultPalette["black"]
    terminal.clear()

    terminal.foregroundColor = resources.defaultPalette["white"]
    menu.rect = BLRect(
      x: terminal.state(BLConstant.WIDTH) / 2 - 10,
      y: terminal.state(BLConstant.HEIGHT) / 2 - 1,
      w: 20,
      h: 2)
    menu.draw(in: terminal)

    terminal.foregroundColor = resources.defaultPalette["green"]
    let rect = BLRect(x: 0, y: 0, w: terminal.state(BLConstant.WIDTH), h: menu.rect.origin.y)
    drawCenteredString(terminal, rect, TITLE)

    terminal.refresh()

    if terminal.hasInput {
      let char = terminal.read()
      _ = menu.handle(char: char)
    }
  }

  func actionStartGame() {
    let worldModel = WorldModel(
      rngStore: RandomSeedStore(seed: 135205160),
      resources: resources,
      mapDefinitions: [
        MapDefinition(id: "1", generatorId: "basic", exits: ["next": "2"]),
        MapDefinition(id: "2", generatorId: "basic", exits: ["next": "3", "previous": "1"]),
        MapDefinition(id: "3", generatorId: "basic", exits: ["next": "4", "previous": "2"]),
        MapDefinition(id: "4", generatorId: "basic", exits: ["next": "5", "previous": "3"]),
        MapDefinition(id: "5", generatorId: "basic", exits: ["previous": "4"]),
      ],
      activeMapId: "1")
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
    } catch {
      NSLog(error.localizedDescription)
      NSLog("Unable to load saved game")
    }
  }

  func actionQuit() {
    director?.quit()
  }
}

