//
//  Director.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/1/18.
//

import Foundation
import BearLibTerminal
#if os(OSX)
  import AppKit
#endif


class Director {
  let terminal: BLTerminalInterface
  let configBlock: (BLTerminalInterface) -> Void

  var shouldExit = false

  var activeScene: Scene?
  var nextScene: Scene?

  init(
    terminal: BLTerminalInterface, configBlock: @escaping (BLTerminalInterface) -> Void) {
    self.terminal = terminal
    self.configBlock = configBlock
    terminal.open()
    configBlock(terminal)
  }

  func run(initialScene: Scene) {
    transition(to: initialScene)
    terminal.refresh()
  }

  func iterate() {
    if let nextScene = nextScene {
      self.nextScene = nil
      _transition(to: nextScene)
    }
    guard let activeScene = self.activeScene, !self.shouldExit else {
      self.quit()
      return
    }
    if terminal.hasInput && terminal.peek() == BLConstant.CLOSE {
      self.quit()
    }
    activeScene.update(terminal: self.terminal)
  }

  func transition(to newScene: Scene) {
    nextScene = newScene
  }

  func _transition(to newScene: Scene?) {
    let oldScene = activeScene
    oldScene?.willExit()
    newScene?.willEnter(with: self)
    activeScene = newScene
    oldScene?.didExit()
    newScene?.didEnter()
  }

  func quit() {
    guard !shouldExit else { return }
    _transition(to: nil)
    shouldExit = true
  }
}


class Scene {
  weak var director: Director?

  func willEnter(with director: Director) {
    self.director = director
  }

  func didEnter() {

  }

  func willExit() {

  }

  func didExit() {

  }

  func update(terminal: BLTerminalInterface) {

  }
}
