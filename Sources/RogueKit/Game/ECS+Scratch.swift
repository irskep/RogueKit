//
//  ECS+Scratch.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/22/18.
//

import Foundation
import BearLibTerminal


class PositionC: ECSComponent {
  var point: BLPoint
  init(entity: Int?, point: BLPoint) {
    self.point = point
    super.init(entity: entity)
  }
}
class PositionS: ECSSystem<PositionC> { }


class SightC: ECSComponent {
  var isBlind = false

  func getCanSeeThrough(level: LevelMap, _ cell: MapCell) -> Bool {
    guard !isBlind else { return false }
    return level.terrains[cell.terrain]?.canSeeThrough == true && (
      cell.feature == 0 || level.features[cell.feature]?.canSeeThrough == true
    )
  }
}
class SightS: ECSSystem<SightC> { }
