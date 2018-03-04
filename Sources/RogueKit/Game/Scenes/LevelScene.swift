//
//  LevelScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


class AStarMover {
  let worldModel: WorldModel
  var points = [BLPoint]()
  var cursorPoint: BLPoint?

  init(worldModel: WorldModel) {
    self.worldModel = worldModel
  }

  func update(cursorPoint: BLPoint?) {
    self.cursorPoint = cursorPoint
    guard let cursorPoint = cursorPoint,
      worldModel.may(entity: worldModel.player, moveTo: cursorPoint),
      worldModel.can(entity: worldModel.player, remember: cursorPoint)
      else {
      points = []
      return
    }
    points.append(worldModel.positionS[worldModel.player]!.point)

    points = Array(astar(
      worldModel.positionS[worldModel.player]!.point,
      goalTestFn: { (point: BLPoint) -> Bool in point == cursorPoint },
      successorFn: {
        (point: BLPoint) -> [BLPoint] in
        return point
          .getNeighbors(bounds: BLRect(size: worldModel.size), diagonals: false)
          .filter({ worldModel.can(entity: worldModel.player, remember: $0) })
          .filter({ worldModel.may(entity: worldModel.player, moveTo: $0) })
      },
      heuristicFn: {
        (point: BLPoint) -> Float in
        return Float(point.manhattanDistance(to: cursorPoint))
      })?.dropLast() ?? [])
  }

  func draw(in terminal: BLTerminalInterface) {
    let oldLayer = terminal.layer
    terminal.layer = BLInt(ZValues.hud)
    terminal.clear(area: BLRect(x: 0, y: 0, w: terminal.state(BLConstant.WIDTH), h: terminal.state(BLConstant.HEIGHT)))
    terminal.foregroundColor = terminal.getColor(a: 50, r: 255, g: 255, b: 255)
    for point in points {
      terminal.put(point: point, code: CP437.BLOCK)
    }
    terminal.layer = oldLayer
  }
}


class LevelScene: Scene, WorldDrawingSceneProtocol {
  let worldModel: WorldModel
  let resources: ResourceCollectionProtocol

  lazy var mover: AStarMover = { return AStarMover(worldModel: self.worldModel) }()
  var cursorPoint: BLPoint = BLPoint.zero
  var inspectedEntity: Entity? {
    return worldModel.entity(at: cursorPoint, matchingPredicate: {
      return self.worldModel.nameS[$0] != nil
    })
  }

  init(resources: ResourceCollectionProtocol, worldModel: WorldModel) {
    self.worldModel = worldModel
    self.resources = resources
  }

  override func willExit() {
    save()
  }

  func save() {
    if let gameURL = URLs.gameURL {
      do {
        let data = try JSONEncoder().encode(worldModel)
        try data.write(to: gameURL)
      } catch {
        NSLog(error.localizedDescription)
        NSLog("WARNING: SAVE FILE IS NOT WORKING")
      }
    }
  }

  var isDirty = true
  override func update(terminal: BLTerminalInterface) {
    var didMove = false
    if terminal.hasInput, let config = (director as? SteveRLDirector)?.config {
      switch terminal.read() {
      case config.keyMenu:
        director?.transition(to: TitleScene(resources: resources))
      case config.keyLeft:
        worldModel.movePlayer(by: BLPoint(x: -1, y: 0))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyRight:
        worldModel.movePlayer(by: BLPoint(x: 1, y: 0))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyUp:
        worldModel.movePlayer(by: BLPoint(x: 0, y: -1))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyDown:
        worldModel.movePlayer(by: BLPoint(x: 0, y: 1))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyWait:
        worldModel.waitPlayer()
        didMove = true
      case config.keyInventoryOpen:
        director?.transition(to: InventoryScene(resources: resources, worldModel: worldModel))

      case config.keyDebugLeft:
        if let id = worldModel.exits["previous"] {
          director?.transition(to: LoadScene(worldModel: worldModel, resources: resources, id: id))
        }
      case config.keyDebugRight:
        if let id = worldModel.exits["next"] {
          director?.transition(to: LoadScene(worldModel: worldModel, resources: resources, id: id))
        }
      case config.keyDebugOmniscience:
        if terminal.check(BLConstant.SHIFT) {
          worldModel.debugFlags["omniscient"] = worldModel.debugFlags["omniscient"] == 1 ? nil : 1
        }
        isDirty = true

      case BLConstant.MOUSE_MOVE:
        let newPoint = BLPoint(
          x: terminal.state(BLConstant.MOUSE_X),
          y: terminal.state(BLConstant.MOUSE_Y))
        if newPoint != cursorPoint {
          isDirty = true
          cursorPoint = newPoint
          mover.update(cursorPoint: cursorPoint)
        }
      case BLConstant.MOUSE_LEFT:
        if !mover.points.isEmpty {
          worldModel.movePlayer(by: mover.points.last! - worldModel.positionS[worldModel.player]!.point)
          mover.update(cursorPoint: mover.cursorPoint)
          didMove = true
        }
      default: break
      }
    }
    if let nextLevelId = worldModel.waitingToTransitionToLevelId {
      didMove = true
      director?.transition(to: LoadScene(worldModel: worldModel, resources: resources, id: nextLevelId))
      return
    }

    if isDirty || didMove {
      isDirty = false
      self.drawWorld(in: terminal)
      mover.draw(in: terminal)
      terminal.refresh()
    }

    if didMove {
      save()
    }
  }
}
