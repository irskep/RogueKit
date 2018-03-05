//
//  AI.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


class AI {
  class func walkRandomly(in worldModel: WorldModel, entity: Entity) -> Bool {
    guard let posC: PositionC = worldModel[entity] else { return false }
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
