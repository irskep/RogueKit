//
//  LevelScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


protocol Animator: class {
  func play(animation: String, source: BLPoint, dest: BLPoint?, callback: (() -> Void)?)
}


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

    points = Array(astar(
      worldModel.positionS[worldModel.player]!.point,
      goalTestFn: { (point: BLPoint) -> Bool in point == cursorPoint },
      successorFn: {
        (point: BLPoint) -> [BLPoint] in
        return point
          .getNeighbors(bounds: BLRect(size: worldModel.size), diagonals: false)
          .filter({ worldModel.can(entity: worldModel.player, remember: $0) })
          .filter({ worldModel.may(entity: worldModel.player, moveThrough: $0) })
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


class LevelScene: Scene, WorldDrawingSceneProtocol, Animator {
  let worldModel: WorldModel
  let resources: ResourceCollectionProtocol

  lazy var mover: AStarMover = { return AStarMover(worldModel: self.worldModel) }()
  var cursorPoint: BLPoint = BLPoint.zero
  var inspectedEntity: Entity?
  var isResting = false

  init(resources: ResourceCollectionProtocol, worldModel: WorldModel) {
    self.worldModel = worldModel
    self.resources = resources
  }

  override func willEnter(with director: Director) {
    super.willEnter(with: director)
    worldModel.animator = self
    worldModel.activeMap.palette.apply(to: BLTerminal.main)  // cheat
    isDirty = true
  }

  override func didEnter() {
    super.didEnter()
//    self.save()
  }

  override func willExit() {
    worldModel.animator = nil
  }

  override func willQuit() {
    super.willQuit()
    self.save()
  }

  func inspectedEntities(at point: BLPoint) -> [Entity] {
    guard worldModel.debugFlags["omniscient"] == 1 ||
      worldModel.playerFOVCache.contains(point) else { return [] }
    return worldModel.entities(at: point, matchingPredicate: {
      return self.worldModel.nameS[$0] != nil
    })
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

  func mayPlayerRest() -> Bool {
    guard let actorC = worldModel.actorS[worldModel.player] else { return false }
    guard actorC.currentStats.hp < actorC.definition.stats.hp || actorC.currentStats.fatigue > 0 else { return false }
    for p in worldModel.playerFOVCache {
      if let m = worldModel.mob(at: p), m != worldModel.player {
        return false
      }
    }
    return true
  }

  func toggleInspectedEntity() {
    let inspectablesInRange = worldModel.playerFOVCache
      .flatMap({
        (point: BLPoint) -> [(BLPoint, Entity)] in
        return self.inspectedEntities(at: point)
          .filter({ $0 != worldModel.player })
          .map { (point, $0) }
      })
      .sorted(by: { $0.0.y == $1.0.y ? $0.0.x < $1.0.x : $0.0.y < $1.0.y })
      .map({ $0.1 })
    guard !inspectablesInRange.isEmpty else { return }
    if let inspectedEntity = inspectedEntity,
      let ix = inspectablesInRange.index(of: inspectedEntity),
      ix != inspectablesInRange.index(before: inspectablesInRange.endIndex)
    {
      self.inspectedEntity = inspectablesInRange[inspectablesInRange.index(after: ix)]
    } else {
      self.inspectedEntity = inspectablesInRange.first
    }
  }

  func drawInspectedEntityOverlay() {
    guard let e = inspectedEntity, let p = worldModel.position(of: e) else { return }
    terminal.layer = BLInt(ZValues.hud)
    var t: timeval = timeval()
    gettimeofday(&t, nil)
    let ms = Int64(t.tv_sec * 1000) + Int64(t.tv_usec / 1000)
    let normalized = Double(ms % 1500) / 1500
    let sinified = (sin(normalized * Double.pi)) / 1
    terminal.foregroundColor = terminal.getColor(a: UInt8(255 * sinified), r: 255, g: 0, b: 0)
    terminal.put(point: p, code: CP437.BLOCK)
    terminal.layer = 0
  }

  var isDirty = true
  var keyReleaseGate = false
  override func update(terminal: BLTerminalInterface) {
    var didMove = false

    if terminal.hasInput, let config = (director as? SteveRLDirector)?.config {
      let key = terminal.read()

      if key & config.keyRest != config.keyRest {
        self.isResting = false
      }

      switch key {
      case config.keyMenu:
        inspectedEntity = nil
        isDirty = true
      case config.keyExit:
        self.save()
        director?.transition(to: TitleScene(resources: resources))

      case config.keyLeft, config.keyLeftAlt:
        guard keyReleaseGate else { break }
        worldModel.movePlayer(by: BLPoint(x: -1, y: 0))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyRight, config.keyRightAlt:
        guard keyReleaseGate else { break }
        worldModel.movePlayer(by: BLPoint(x: 1, y: 0))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyUp, config.keyUpAlt:
        guard keyReleaseGate else { break }
        worldModel.movePlayer(by: BLPoint(x: 0, y: -1))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyDown, config.keyDownAlt:
        guard keyReleaseGate else { break }
        worldModel.movePlayer(by: BLPoint(x: 0, y: 1))
        mover.update(cursorPoint: nil)
        didMove = true
      case config.keyWait:
        guard keyReleaseGate else { break }
        worldModel.waitPlayer()
        didMove = true
      case config.keyRest:
        guard keyReleaseGate else { break }
        self.isResting = true

      case config.keyInventoryOpen:
        director?.transition(to: InventoryScene(
          resources: resources,
          worldModel: worldModel,
          returnToScene: self,
          state: .willOpenMenu))
      case config.keyEquip:
        director?.transition(to: InventoryScene(
          resources: resources,
          worldModel: worldModel,
          returnToScene: self,
          state: .willEquip))
      case config.keyDrop:
        director?.transition(to: InventoryScene(
          resources: resources,
          worldModel: worldModel,
          returnToScene: self,
          state: .willDrop))
      case config.keyHelp where terminal.check(BLConstant.SHIFT):
        director?.transition(to: HelpScene(
          resources: resources,
          worldModel: worldModel,
          returnToScene: self))
      case config.keyToggleInspectedEntity:
        self.toggleInspectedEntity()
        isDirty = true
      case config.keyRangedFire:
        guard keyReleaseGate else { break }
        self.rangedFire()
        didMove = true
      case config.keyStim:
        guard keyReleaseGate else { break }
        isDirty = true
        if worldModel.haveEntityUseStim(entity: worldModel.player) {
          didMove = true
        }
      case config.keyHealth:
        guard keyReleaseGate else { break }
        isDirty = true
        if worldModel.haveEntityUseHealth(entity: worldModel.player) {
          didMove = true
        }
      case config.keyDebugLeft:
        if let id = worldModel.exits["previous"] {
          director?.transition(to: LoadScene(worldModel: worldModel, resources: resources, id: id))
        }
      case config.keyDebugRight:
        if let id = worldModel.exits["next"] {
          if id == "win" {
            director?.transition(to: WinScene(resources: resources))
          } else {
            director?.transition(to: LoadScene(worldModel: worldModel, resources: resources, id: id))
          }
        }
      case config.keyDebugOmniscience:
        if terminal.check(BLConstant.SHIFT) {
          worldModel.debugFlags["omniscient"] = worldModel.debugFlags["omniscient"] == 1 ? nil : 1
        }
        isDirty = true
      case config.keyDebugInvincible:
        if terminal.check(BLConstant.SHIFT) {
          worldModel.debugFlags["invincible"] = worldModel.debugFlags["invincible"] == 1 ? nil : 1
        }
        isDirty = true

      case BLConstant.MOUSE_MOVE:
        let newPoint = BLPoint(
          x: terminal.state(BLConstant.MOUSE_X),
          y: terminal.state(BLConstant.MOUSE_Y))
        if newPoint != cursorPoint {
          isDirty = true
          cursorPoint = newPoint
          inspectedEntity = self.inspectedEntities(at: cursorPoint).first
          mover.update(cursorPoint: cursorPoint)
        }
      case BLConstant.MOUSE_LEFT:
        if let e = inspectedEntity, worldModel.moveAfterPlayerS[e] != nil {
          worldModel.fightPlayer(defender: e)
          didMove = true
        } else if !mover.points.isEmpty {
          worldModel.movePlayer(by: mover.points.last! - worldModel.positionS[worldModel.player]!.point)
          mover.update(cursorPoint: mover.cursorPoint)
          didMove = true
        }
      default: break
      }

      if key & BLConstant.KEY_RELEASED != 0 {
        keyReleaseGate = true
      } else {
        keyReleaseGate = false
      }
    }

    if self.isResting && self.mayPlayerRest() {
      worldModel.waitPlayer()
      didMove = true
    }

    if didMove {
      if let e = worldModel.lastEntityAttackedByPlayer {
        inspectedEntity = e
        worldModel.lastEntityAttackedByPlayer = nil
      }

      if let e = inspectedEntity,
        let ep = worldModel.position(of: e),
        worldModel.can(entity: worldModel.player, see: ep)
      {
        // actually do nothing, it's fine
      } else {
        inspectedEntity = nil
        isDirty = true
      }
    }
    if let nextLevelId = worldModel.waitingToTransitionToLevelId {
      didMove = true
      if nextLevelId == "win" {
        director?.transition(to: WinScene(resources: resources))
      } else {
        director?.transition(to: LoadScene(worldModel: worldModel, resources: resources, id: nextLevelId))
      }
      return
    }

    if isDirty || didMove {
      isDirty = false
      self.drawWorld(in: terminal)
      mover.draw(in: terminal)
    }

    drawInspectedEntityOverlay()
    terminal.refresh()

    if didMove && !isResting {
      if worldModel.gameHasntEnded {
//        save()
      } else {
        director?.transition(to: LoseScene(resources: resources))
      }
    }

    // drain event queue every frame
    if terminal.hasInput { self.update(terminal: terminal) }
  }

  func rangedFire() {
    guard let e = inspectedEntity else { return }
    if worldModel.moveAfterPlayerS[e] != nil {
      worldModel.fightPlayer(defender: e)
    } else if let p = worldModel.position(of: e), let lastPoint = mover.points.last {
      mover.update(cursorPoint: p)
      worldModel.movePlayer(by: lastPoint - worldModel.positionS[worldModel.player]!.point)
      mover.update(cursorPoint: p)
    }
  }

  func play(animation: String, source: BLPoint, dest: BLPoint?, callback: (() -> Void)?)
  {
    switch (animation, dest) {
    case ("laser", .some(let dest)): self.playLineAnimation(
      source: source, dest: dest,
      color: "red", h: "-", v: "|", nw: "\\", ne: "/", sw: "/", se: "\\",
      callback: callback)
    case ("poop", .some(let dest)): self.playLineAnimation(
      source: source, dest: dest,
      color: "brown", h: "*", v: "*", nw: "*", ne: "*", sw: "*", se: "*",
      callback: callback)
    case ("shoot", .some(let dest)): self.playLineAnimation(
      source: source, dest: dest,
      color: "white", h: ".", v: "*", nw: "*", ne: "*", sw: "*", se: "*",
      callback: callback)
    case ("shock", .some(let dest)): self.playLineAnimation(
      source: source, dest: dest,
      color: "teal", h: "-", v: "|", nw: "\\", ne: "/", sw: "/", se: "\\",
      callback: callback)
    case ("exhausted", _):
      self.playExhaustedAnimation(source: source, callback: callback)
    case ("notice", _):
      self.playNoticeAnimation(source: source, callback: callback)
    default: callback?()
    }
  }

  func playExhaustedAnimation(source: BLPoint, callback: (() -> Void)?) {
    let drawWorld: () -> Void = {
      self.drawWorld(in: terminal)
      self.drawInspectedEntityOverlay()
    }
    for i: BLInt in [1, 2, 3] {
      drawWorld()

      let oldLayer = terminal.layer
      terminal.layer = BLInt(ZValues.animations)
      terminal.foregroundColor = terminal.getColor(name: "teal")
      terminal.print(point: source + BLPoint(x: -1 * i, y: -1 * i), string: "z")
      terminal.layer = oldLayer
      terminal.refresh()
      terminal.delay(milliseconds: 33)
      if terminal.hasInput {
        callback?()
        return
      }
    }
    callback?()
  }

  func playNoticeAnimation(source: BLPoint, callback: (() -> Void)?) {
    let drawWorld: () -> Void = {
      self.drawWorld(in: terminal)
      self.drawInspectedEntityOverlay()
    }
    for v: Bool in [true, false, true, false] {
      drawWorld()

      if v {
        let oldLayer = terminal.layer
        terminal.layer = BLInt(ZValues.animations)
        terminal.foregroundColor = terminal.getColor(name: "gray")
        terminal.print(point: source + BLPoint(x: -1, y: -1), string: "\\")
        terminal.print(point: source + BLPoint(x: 1, y: 1), string: "\\")
        terminal.print(point: source + BLPoint(x: -1, y: 1), string: "/")
        terminal.print(point: source + BLPoint(x: 1, y: -1), string: "/")
        terminal.layer = oldLayer
      }
      terminal.refresh()
      terminal.delay(milliseconds: 33)
      if terminal.hasInput {
        callback?()
        return
      }
    }
    callback?()
  }

  func playLineAnimation(
    source: BLPoint, dest: BLPoint,
    color: String,
    h: String, v: String, nw: String, ne: String, sw: String, se: String,
    callback: (() -> Void)?)
  {
    let drawWorld: () -> Void = {
      self.drawWorld(in: terminal)
      self.drawInspectedEntityOverlay()
    }
    var last: BLPoint!
    for point in source.bresenham(to: dest) {
      if last == nil {
        last = point
        continue
      }
      let delta = point - last
      let char: String
      if delta.x < 0 {
        if delta.y < 0 {
          char = nw
        } else if delta.y > 0 {
          char = sw
        } else {
          char = h
        }
      } else if delta.x > 0 {
        if delta.y < 0 {
          char = ne
        } else if delta.y > 0 {
          char = se
        } else {
          char = h
        }
      } else {
        char = v
      }

      drawWorld()
      let oldLayer = terminal.layer
      terminal.layer = BLInt(ZValues.animations)
      terminal.foregroundColor = terminal.getColor(name: color)
      terminal.print(point: point, string: char)
      terminal.layer = oldLayer
      terminal.refresh()
      terminal.delay(milliseconds: 33)
      if terminal.hasInput {
        callback?()
        return
      }
    }
    callback?()
  }
}
