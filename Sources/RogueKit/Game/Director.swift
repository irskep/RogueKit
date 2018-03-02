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
    guard let activeScene = self.activeScene, !self.shouldExit else {
      self.shouldExit = true
      self.terminate()
      return
    }
    activeScene.update(terminal: self.terminal)
  }

  func transition(to newScene: Scene) {
    print("transition to", newScene)
    let oldScene = activeScene
    oldScene?.willExit()
    newScene.willEnter(with: self)
    activeScene = newScene
    oldScene?.didExit()
    newScene.didEnter()
    print("done transitioning to", newScene)
  }

  func quit() {
    print("quit")
    shouldExit = true
  }

  func terminate() {
    print("terminate")
    #if os(OSX)
      NSApp.stop(nil)
    #endif
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
