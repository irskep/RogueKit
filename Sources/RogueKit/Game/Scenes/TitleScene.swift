//
//  TitleScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal

let TITLE = """
 _____                        _ _ _
|  __ \\                      | (_) |
| |__) |___   __ _ _   _  ___| |_| | _____
|  _  // _ \\ / _` | | | |/ _ \\ | | |/ / _ \\
| | \\ \\ (_) | (_| | |_| |  __/ | |   <  __/
|_|  \\_\\___/ \\__, |\\__,_|\\___|_|_|_|\\_\\___|
              __/ |
             |___/
"""


func drawCenteredString(_ terminal: BLTerminalInterface, _ box: BLRect, _ s: String) {
  let stringSize = terminal.measure(string: s)
  let x = box.x + box.w / 2 - stringSize.w / 2
  let y = box.y + box.h / 2 - stringSize.h / 2
  terminal.print(point: BLPoint(x: x, y: y), string: s)
}


class TitleScene: Scene {
  let resources: ResourceCollection
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

  init(resources: ResourceCollection) {
    self.resources = resources
  }

  override func update(terminal: BLTerminalInterface) {
    terminal.clear()

    let stringSize = terminal.measure(string: TITLE)
    terminal.foregroundColor = terminal.getColor(a: 255, r: 255, g: 255, b: 255)
    let rect = BLRect(x: 0, y: 0, w: terminal.state(BLConstant.WIDTH), h: stringSize.h)
    drawCenteredString(terminal, rect, TITLE)

    menu.rect = BLRect(
      x: terminal.state(BLConstant.WIDTH) / 2 - 10,
      y: terminal.state(BLConstant.HEIGHT) / 2 - 1,
      w: 20,
      h: 2)
    menu.draw(in: terminal)

    terminal.refresh()

    if terminal.hasInput {
      let char = terminal.read()
      _ = menu.handle(char: char)
    }
  }

  func actionStartGame() {
    let worldModel = WorldModel(
      rngStore: RandomSeedStore(seed: 135205160),
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

class SimpleMenu {
  var rect: BLRect
  let items: [(Int32, String, () -> Void)]

  init(rect: BLRect, items: [(Int32, String, () -> Void)]) {
    self.rect = rect
    self.items = items
  }

  func draw(in terminal: BLTerminalInterface) {
    var y = rect.y
    terminal.foregroundColor = terminal.getColor(a: 255, r: 255, g: 255, b: 255)
    for (key, label, _) in items {
      terminal.print(
        point: BLPoint(x: rect.x, y: y),
        string: "(\(BLConstant.label(for: key) ?? "???")) \(label)")
      y += 1
    }
  }

  func handle(char: Int32) -> Bool {
    for (key, _, callback) in items {
      if key == char {
        callback()
        return true
      }
    }
    return false
  }
}

