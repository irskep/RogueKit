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
  func assemble(
    entity: Entity,
    worldModel: WorldModel,
    poiString: String,
    point: BLPoint?,
    levelId: String?)
}


//class PlayerAssembly: EntityAssemblyProtocol {
//  func assemble(
//    entity: Entity,
//    worldModel: WorldModel,
//    poiString: String,
//    point: BLPoint?,
//    levelId: String?)
//  {
//    worldModel.nameS.add(component:
//      NameC(entity: entity, name: "You", description: "An adventurer of subjective gender"))
//    worldModel.sightS.add(component:
//      SightC(entity: entity))
//    worldModel.positionS.add(component:
//      PositionC(entity: entity, point: point ?? BLPoint.zero, levelId: levelId))
//    worldModel.fovS.add(component: FOVC(entity: entity))
//    worldModel.spriteS.add(component:
//      SpriteC(entity: entity,
//              int: nil,
//              str: "@",
//              z: ZValues.player,
//              color: worldModel.resources!.defaultPalette["white"]))
//    worldModel.actorS.add(component:
//      ActorC(entity: entity,
//             definition: worldModel.csvDB.actors["player"]!,
//             currentStats: nil)).currentStats.fatigue = 0
//    worldModel.factionS.add(component: FactionC(entity: entity, faction: "Test Subjects"))
//    worldModel.forceWaitS.add(component: ForceWaitC(entity: entity))
//
//    let inventoryC = worldModel.inventoryS.add(component:
//      InventoryC(entity: entity))
//
//    // Player just starts with their fist
//    worldModel.wieldingS.add(entity: entity, component: WieldingC(
//      entity: entity,
//      weaponEntity: nil,
//      defaultWeaponDefinition: worldModel.csvDB.weapons["fist"]!))
//
//    // And a shirt
//    let equipmentC = worldModel.equipmentS.add(
//      component: EquipmentC(entity: entity))
//    let bodyArmorE = worldModel.addEntity()
//    inventoryC.add(entity: bodyArmorE)
//    ArmorAssembly().assemble(
//      entity: bodyArmorE,
//      worldModel: worldModel,
//      poiString: "playerstart",
//      point: nil,
//      levelId: levelId)
//    equipmentC.put(armor: bodyArmorE, on: .body)
//  }
//}


class EnemyAssembly: EntityAssemblyProtocol {
  func assemble(
    entity: Entity,
    worldModel: WorldModel,
    poiString: String,
    point: BLPoint?,
    levelId: String?)
  {
    let actorTags = poiString.split(separator: ",").map { String($0) }
    let actorDefinition = WeightedChoice.choose(
      rng: worldModel.mapRNG, items: worldModel.csvDB.actors(matching: actorTags))

    if actorDefinition.ai == "player" {
      worldModel.fovS.add(component: FOVC(entity: entity))
    } else {
      worldModel.moveAfterPlayerS.add(component:
        MoveAfterPlayerC(entity: entity, state: .wandering))
    }

    worldModel.nameS.add(component:
      NameC(entity: entity,
            name: actorDefinition.name,
            description: actorDefinition.description))
    worldModel.sightS.add(component:
      SightC(entity: entity))
    worldModel.positionS.add(component:
      PositionC(entity: entity, point: point ?? BLPoint.zero, levelId: levelId))
    worldModel.spriteS.add(component:
      SpriteC(entity: entity,
              int: actorDefinition.char,
              str: nil,
              z: ZValues.enemy,
              color: worldModel.resources!.defaultPalette[actorDefinition.color]))
    worldModel.actorS.add(component:
      ActorC(entity: entity,
             definition: actorDefinition,
             currentStats: nil)).currentStats.fatigue = 0
    worldModel.factionS.add(component: FactionC(entity: entity, faction: actorDefinition.faction))
    worldModel.forceWaitS.add(component: ForceWaitC(entity: entity))
    let inventoryC = worldModel.inventoryS.add(component: InventoryC(entity: entity))

    let equipmentC = worldModel.equipmentS.add(
      component: EquipmentC(entity: entity))

    let allowedStartingEquipment = worldModel.csvDB.armors(matching: actorDefinition.id)

    // Add starting armor, if any is allowed
    for slot in EquipmentC.Slot.all {
      let options = allowedStartingEquipment.filter({ $0.slot == slot.rawValue})
      guard !options.isEmpty else { continue }
      let option = WeightedChoice.choose(rng: worldModel.mapRNG, items: options).id
      let e = worldModel.addEntity()
      inventoryC.add(entity: e)
      ArmorAssembly().assemble(
        entity: e, worldModel: worldModel, poiString: "#" + option,
        point: nil, levelId: levelId)
      equipmentC.put(armor: e, on: slot)
    }

    let wieldingC = worldModel.wieldingS.add(component: WieldingC(
      entity: entity,
      weaponEntity: nil,
      defaultWeaponDefinition: worldModel.csvDB.weapons[actorDefinition.defaultWeapon]!))

    if !worldModel.csvDB.weapons(matching: actorDefinition.id).isEmpty {
      let weaponE = worldModel.addEntity()
      wieldingC.weaponEntity = weaponE
      inventoryC.add(entity: weaponE)

      WeaponAssembly().assemble(
        entity: weaponE,
        worldModel: worldModel,
        poiString: actorDefinition.id,  // actor defn ID doubles as weapon tag
        point: nil,
        levelId: levelId)
    }
  }
}


class WeaponAssembly: EntityAssemblyProtocol {
  func assemble(
    entity: Entity,
    worldModel: WorldModel,
    poiString: String,
    point: BLPoint?,
    levelId: String?)
  {
    let weaponDef: WeaponDefinition
    if poiString.hasPrefix("#") {
      weaponDef = worldModel.csvDB.weapons[String(poiString.dropFirst())]!
    } else {
      let allowedWeapons = worldModel.csvDB.weapons(
        matching: poiString.split(separator: ",").map({ String($0) }))
      weaponDef = WeightedChoice.choose(rng: worldModel.mapRNG, items: allowedWeapons)
    }

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


class ArmorAssembly: EntityAssemblyProtocol {
  func assemble(
    entity: Entity,
    worldModel: WorldModel,
    poiString: String,
    point: BLPoint?,
    levelId: String?)
  {
    let armorDef: ArmorDefinition
    if poiString.hasPrefix("#") {
      armorDef = worldModel.csvDB.armors[String(poiString.dropFirst())]!
    } else {
      let allowedArmors = worldModel.csvDB.armors(
        matching: poiString.split(separator: ",").map({ String($0) }))
      armorDef = WeightedChoice.choose(rng: worldModel.mapRNG, items: allowedArmors)
    }

    worldModel.nameS.add(component:
      NameC(entity: entity,
            name: armorDef.name,
            description: armorDef.description))

    if let point = point {
      worldModel.positionS.add(component:
        PositionC(entity: entity, point: point, levelId: levelId))
    }

    worldModel.spriteS.add(component:
      SpriteC(entity: entity,
              int: armorDef.char,
              str: nil, z: ZValues.item,
              color: worldModel.resources!.defaultPalette[armorDef.color]))
    worldModel.collectibleS.add(component:
      CollectibleC(entity: entity,
                   grams: armorDef.grams,
                   liters: armorDef.liters))
    worldModel.armorS.add(component:
      ArmorC(entity: entity, armorDefinition: armorDef))
  }
}


let ASSEMBLIES: [String: EntityAssemblyProtocol] = {
  return [
    "enemy": EnemyAssembly(),
    "weapon": WeaponAssembly(),
    "armor": ArmorAssembly(),
  ]
}()
