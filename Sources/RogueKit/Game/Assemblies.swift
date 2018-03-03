//
//  Assemblies.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


protocol EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?)
}


class PlayerAssembly: EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?) {
    worldModel.sightS.add(component:
      SightC(entity: entity))
    worldModel.positionS.add(component:
      PositionC(entity: entity, point: point ?? BLPoint.zero, levelId: levelId))
    worldModel.fovS.add(component:
      FOVC(entity: entity))
    worldModel.spriteS.add(component:
      SpriteC(entity: entity, int: nil, str: "@", z: 100))
    worldModel.inventoryS.add(component:
      InventoryC(entity: entity))
  }
}


class EnemyAssembly: EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?) {
    worldModel.sightS.add(component:
      SightC(entity: entity))
    worldModel.positionS.add(component:
      PositionC(entity: entity, point: point ?? BLPoint.zero, levelId: levelId))
    worldModel.spriteS.add(component:
      SpriteC(entity: entity, int: nil, str: "E", z: 2))
    worldModel.moveAfterPlayerS.add(component:
      MoveAfterPlayerC(entity: entity, behaviorType: .walkRandomly))
  }
}


class ItemAssembly: EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?) {
    worldModel.positionS.add(component:
      PositionC(entity: entity, point: point ?? BLPoint.zero, levelId: levelId))
    worldModel.spriteS.add(component:
      SpriteC(entity: entity, int: nil, str: "i", z: 1))
    worldModel.collectibleS.add(component:
      CollectibleC(entity: entity, grams: 1000, liters: 1))
  }
}


let ASSEMBLIES: [String: EntityAssemblyProtocol] = {
  return [
    "enemy": EnemyAssembly(),
    "item": ItemAssembly(),
  ]
}()
