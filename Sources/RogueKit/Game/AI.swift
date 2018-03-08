//
//  AI.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal



extension WorldModel {
  func aStar(entity: Entity, start: BLPoint, end: BLPoint, rng: RKRNGProtocol?) -> [BLPoint]? {
    let result = astar(
      start,
      goalTestFn: { (point: BLPoint) -> Bool in point == end },
      successorFn: {
        (point: BLPoint) -> [BLPoint] in
        var results = point
          .getNeighbors(bounds: BLRect(size: self.size), diagonals: false)
          .filter({ self.can(entity: entity, remember: $0) })
          .filter({ self.may(entity: entity, moveTo: $0) })
        if let rng = rng { rng.shuffleInPlace(&results) }
        return results
    },
      heuristicFn: {
        (point: BLPoint) -> Float in
        return Float(point.manhattanDistance(to: end))
    })
    if let result = result { return Array(result) } else { return nil }
  }
}



// MARK: AI or something


class MoveAfterPlayerC: ECSComponent, Codable {
  var entity: Entity?

  enum State: String {
    case standingStill
    case wandering
    case pursuingPlayer
  }

  var stateString: String = "standStill"
  var state: State {
    get { return State(rawValue: stateString)! }
    set { stateString = newValue.rawValue }
  }

  var intendedPath: [BLPoint]?
  var lastTargetPos: BLPoint?
  var target: Entity?

  init(entity: Entity?) {
    self.entity = entity
  }

  convenience init(entity: Entity?, state: State) {
    self.init(entity: entity)
    self.state = state
  }

  func execute(in worldModel: WorldModel) -> Bool {
    guard let entity = entity,
      let actorC = worldModel.actorS[entity],
      let nameC = worldModel.nameS[entity]
      else { return false }
    if let forceWaitC = worldModel.forceWaitS[entity] {
      if forceWaitC.turnsRemaining > 0 {
        worldModel.log("\(nameC.name) stumbles from exhaustion")
        forceWaitC.turnsRemaining -= 1
        return false
      }

      if actorC.fatigueLevel > 0 {
        // we are already taking this turn, but we'll take 1 or 2 more after
        // this one to recover from exhaustion
        forceWaitC.turnsRemaining = actorC.fatigueLevel
      }
    }

    let stats = actorC.currentStats
    // TODO: have mob notice entities of OTHER FACTIONS as well as just the
    // player!
    if worldModel.canMobSeePlayer(entity) {
      switch state {
      case .standingStill, .wandering:
        if worldModel.mapRNG.get() <= _100(stats.awareness) {
          self.state = .pursuingPlayer
          self.target = worldModel.player
          self.lastTargetPos = worldModel.playerPos
          worldModel.log("\(nameC.name) notices you")
          return true
        }
      default: break
      }
    }

    switch state {
    case .standingStill: return true
    case .wandering: return walkRandomly(in: worldModel)
    case .pursuingPlayer:
      let val = pursue(in: worldModel)
      if val {
        return true
      } else {
        self.state = .wandering
        self.intendedPath = nil
        self.target = nil
        self.lastTargetPos = nil
        return false
      }
    }
  }

  func walkRandomly(in worldModel: WorldModel) -> Bool {
    guard let entity = entity, let posC: PositionC = worldModel[entity] else { return false }
    let options = posC.point
      .getNeighbors(bounds: BLRect(size: worldModel.size), diagonals: false)
      .filter({ worldModel.may(entity: entity, moveTo: $0) })
    guard !options.isEmpty else { return false }

    let nextPoint: BLPoint
    if options.contains(worldModel.playerPos) {
      nextPoint = worldModel.playerPos
    } else {
      nextPoint = worldModel.mapRNG.choice(Array(options))
    }
    return worldModel.push(entity: entity, by: nextPoint - posC.point)
  }

  func regenerateIntendedPath(in worldModel: WorldModel) {
    guard
      let entity = entity,
      let target = target,
      let entityPos = worldModel.position(of: entity),
      let targetPos = worldModel.position(of: target),
      let path = worldModel.aStar(entity: entity, start: entityPos, end: targetPos, rng: worldModel.mapRNG)
      else { return }
    self.intendedPath = path.dropLast().reversed()
    self.target = target
  }

  func pursue(in worldModel: WorldModel) -> Bool {
    guard let entity = entity,
      let target = target,
      let targetPos = worldModel.positionS[target]?.point,
      let entityPos = worldModel.positionS[entity]?.point
      else { return false }

    if targetPos.manhattanDistance(to: entityPos) == 1 {
      return worldModel.push(entity: entity, by: targetPos - entityPos)
    }

    if targetPos != lastTargetPos || intendedPath == nil {
      // If target has moved or there is an obstacle in the way, regenerate the path
      self.regenerateIntendedPath(in: worldModel)
    } else if let path = intendedPath, let first = path.first, !worldModel.may(entity: entity, moveTo: first) {
      self.regenerateIntendedPath(in: worldModel)
    }
    lastTargetPos = targetPos

    // If holding a ranged weapon and have more than 40% chance to hit, fire!
    if worldModel.weapon(wieldedBy: entity)?.isRanged == true,
      worldModel.can(entity: worldModel.player, see: entityPos),
      let outcome = worldModel.predictFight(attacker: entity, defender: target),
      outcome.hitChance >= 0.4 {
      return worldModel.fight(attacker: entity, defender: target)
    }

    // If there is a path, move along it by one cell and update the path
    guard let path = intendedPath, let first = path.first else { return false }

    if worldModel.push(entity: entity, by: first - entityPos) {
      self.intendedPath = Array(path.dropFirst())
      return true
    } else {
      return false
    }
  }
}
class MoveAfterPlayerS: ECSSystem<MoveAfterPlayerC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}
