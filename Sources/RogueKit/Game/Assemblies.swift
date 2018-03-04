//
//  Assemblies.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


struct ZValues {
  static let floor: Int = -1
  static let feature: Int = 0
  static let item: Int = 1
  static let enemy: Int = 2
  static let player: Int = 3
  static let hud: Int = 100
  static let modal: Int = 101
}


protocol EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?)
}


class PlayerAssembly: EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?) {
    worldModel.nameS.add(component:
      NameC(entity: entity, name: "You", description: "An adventurer of subjective gender"))
    worldModel.sightS.add(component:
      SightC(entity: entity))
    worldModel.positionS.add(component:
      PositionC(entity: entity, point: point ?? BLPoint.zero, levelId: levelId))
    worldModel.fovS.add(component:
      FOVC(entity: entity))
    worldModel.spriteS.add(component:
      SpriteC(entity: entity,
              int: nil,
              str: "@",
              z: ZValues.player,
              color: worldModel.resources!.defaultPalette["white"]))
    worldModel.inventoryS.add(component:
      InventoryC(entity: entity))
    worldModel.statsS.add(component:
      StatsC(entity: entity,
             baseStats: worldModel.csvDB.stats["player"]!,
             currentStats: nil))

    // Player just starts with their fist
    worldModel.wieldingS.add(entity: entity, component: WieldingC(
      entity: entity,
      weaponEntity: nil,
      defaultWeaponDefinition: worldModel.csvDB.weapons["fist"]!))
  }
}


class EnemyAssembly: EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?) {
    worldModel.nameS.add(component:
      NameC(entity: entity, name: "An enemy", description: "I haven't implemented this stuff yet."))
    worldModel.sightS.add(component:
      SightC(entity: entity))
    worldModel.positionS.add(component:
      PositionC(entity: entity, point: point ?? BLPoint.zero, levelId: levelId))
    worldModel.spriteS.add(component:
      SpriteC(entity: entity,
              int: nil,
              str: "E",
              z: ZValues.enemy,
              color: worldModel.resources!.defaultPalette["green"]))
    worldModel.moveAfterPlayerS.add(component:
      MoveAfterPlayerC(entity: entity, behaviorType: .walkRandomly))
    worldModel.statsS.add(component:
      StatsC(entity: entity,
             baseStats: worldModel.csvDB.stats["generic_mob"]!,
             currentStats: nil))

    let weaponE = worldModel.addEntity()
    // Give it a random weapon
    worldModel.wieldingS.add(entity: entity, component: WieldingC(
      entity: entity,
      weaponEntity: weaponE,
      defaultWeaponDefinition: worldModel.csvDB.weapons["fist"]!))

    WeaponAssembly().assemble(
      entity: weaponE,
      worldModel: worldModel,
      point: nil,
      levelId: levelId)
  }
}


class WeaponAssembly: EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?) {
    // TODO: get weapon tag from prefab instead of using a constant
//    guard let levelId = levelId, let level = worldModel.maps[levelId] else { return }
    let tag = "basic"
    let allowedWeapons = worldModel.csvDB.weapons.values.filter({ $0.tags.contains(tag) })
    let weaponDef = worldModel.mapRNG.choice(allowedWeapons)

//    print(weaponDef)

    worldModel.nameS.add(component:
      NameC(entity: entity,
            name: weaponDef.name,
            description: weaponDef.description))

    if let point = point {
      worldModel.positionS.add(component:
        PositionC(entity: entity, point: point, levelId: levelId))
    }

    worldModel.spriteS.add(component:
      SpriteC(entity: entity,
              int: weaponDef.char,
              str: nil, z: ZValues.item,
              color: worldModel.resources!.defaultPalette[weaponDef.color]))
    worldModel.collectibleS.add(component:
      CollectibleC(entity: entity,
                   grams: weaponDef.grams,
                   liters: weaponDef.liters))
    worldModel.weaponS.add(component:
      WeaponC(entity: entity, weaponDefinition: weaponDef))
  }
}


let ASSEMBLIES: [String: EntityAssemblyProtocol] = {
  return [
    "enemy": EnemyAssembly(),
    "weapon": WeaponAssembly(),
  ]
}()
