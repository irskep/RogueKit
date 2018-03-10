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
          .filter({ self.may(entity: entity, moveThrough: $0) })
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
    case pursuingHiddenTarget
    case fightingVisibleTarget
  }

  var stateString: String = State.wandering.rawValue
  var state: State {
    get { return State(rawValue: stateString)! }
    set { stateString = newValue.rawValue }
  }

  var isAttacked = false
//  var hasNoticedTarget = false
  var target: Entity?

  var chasePath: [BLPoint]?

  init(entity: Entity?) {
    self.entity = entity
  }

  convenience init(entity: Entity?, state: State) {
    self.init(entity: entity)
    self.state = state
  }

  func execute(in worldModel: WorldModel) -> Bool {
    guard let entity = entity,
      let entityPos = worldModel.position(of: entity),
      let actorC = worldModel.actorS[entity],
      let nameC = worldModel.nameS[entity]
      else { return false }
    if let forceWaitC = worldModel.forceWaitS[entity] {
      if forceWaitC.turnsRemaining > 0 {
        worldModel.log("\(nameC.name) stumbles from exhaustion")
        if let pos = worldModel.position(of: entity), worldModel.can(entity: worldModel.player, see: pos) {
          worldModel.animator?.play(animation: "exhausted", source: pos, dest: nil, callback: nil)
        }
        forceWaitC.turnsRemaining -= 1
        return false
      }

      if actorC.fatigueLevel > 0 {
        // we are already taking this turn, but we'll take 1 or 2 more after
        // this one to recover from exhaustion
        forceWaitC.turnsRemaining = actorC.fatigueLevel
      }
    }

    target = worldModel.player

    guard let target = target,
        let targetPos = worldModel.position(of: target)
        else {
      return self.walkRandomly(in: worldModel)
    }

    let stats = actorC.currentStats

    switch state {
    case .wandering, .standingStill:
      if worldModel.canMobSeePlayer(entity) && (worldModel.mapRNG.get() <= _100(stats.awareness) || isAttacked) {
        self.state = .fightingVisibleTarget
        worldModel.log("\(nameC.name) notices you")
        worldModel.animator?.play(animation: "notice", source: entityPos, dest: nil, callback: nil)
        chasePath = worldModel.aStar(
          entity: entity,
          start: entityPos,
          end: targetPos,
          rng: worldModel.mapRNG)?.dropLast().reversed()
        return true
      } else {
        if state == .wandering {
          return walkRandomly(in: worldModel)
        } else {
          return true
        }
      }
    case .pursuingHiddenTarget:
      isAttacked = false
      if worldModel.canMobSeePlayer(entity) {
        state = .fightingVisibleTarget
        fallthrough
      } else if self.chase(in: worldModel) {
        return true
      } else {
        self.state = .wandering
        return walkRandomly(in: worldModel)
      }
    case .fightingVisibleTarget:
      isAttacked = false
      if worldModel.canMobSeePlayer(entity) {
        chasePath = worldModel.aStar(
          entity: entity,
          start: entityPos,
          end: targetPos,
          rng: worldModel.mapRNG)?.dropLast().reversed()
      } else {
        state = .pursuingHiddenTarget
        if var chasePath = chasePath, !chasePath.isEmpty {
          let ret = worldModel.push(entity: entity, by: chasePath.removeFirst() - entityPos)
          self.chasePath = chasePath
          return ret
        } else {
          return false
        }
      }
      if let outcome = worldModel.predictFight(attacker: entity, defender: target),
        outcome.hitChance >= 0.4
      {
        return worldModel.fight(attacker: entity, defender: target)
      } else if worldModel.weapon(wieldedBy: entity)?.isMelee == true {
        let dest = worldModel._playerGoalMap.neighbor(of: entityPos, closestToValue: 0)
        return worldModel.push(entity: entity, by: dest - entityPos)
      } else {
        let dest = worldModel._playerGoalMap.neighbor(of: entityPos, closestToValue: 2)
        return worldModel.push(entity: entity, by: dest - entityPos)
      }
    }
  }

  func chase(in worldModel: WorldModel) -> Bool {
    guard let entity = entity,
      var chasePath = chasePath,
      !chasePath.isEmpty,
      let entityPos = worldModel.position(of: entity) else { return false }
    let ret = worldModel.push(entity: entity, by: chasePath.removeFirst() - entityPos)
    self.chasePath = chasePath
    return ret
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
}
class MoveAfterPlayerS: ECSSystem<MoveAfterPlayerC>, Codable {
  required init(from decoder: Decoder) throws { try super.init(from: decoder) }
  required init() { super.init() }
  override func encode(to encoder: Encoder) throws { try super.encode(to: encoder) }
}
