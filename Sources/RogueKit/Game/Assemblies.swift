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
    point: BLPoint?,
    levelId: String?)
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
    worldModel.statsS.add(component:
      StatsC(entity: entity,
             baseStats: worldModel.csvDB.stats["player"]!,
             currentStats: nil)).currentStats.fatigue = 0
    worldModel.factionS.add(component: FactionC(entity: entity, faction: "Test Subjects"))
    worldModel.forceWaitS.add(component: ForceWaitC(entity: entity))

    let inventoryC = worldModel.inventoryS.add(component:
      InventoryC(entity: entity))

    // Player just starts with their fist
    worldModel.wieldingS.add(entity: entity, component: WieldingC(
      entity: entity,
      weaponEntity: nil,
      defaultWeaponDefinition: worldModel.csvDB.weapons["fist"]!))

    // And a shirt
    let equipmentC = worldModel.equipmentS.add(
      component: EquipmentC(entity: entity))
    let bodyArmorE = worldModel.addEntity()
    inventoryC.add(entity: bodyArmorE)
    ArmorAssembly().assemble(
      entity: bodyArmorE,
      worldModel: worldModel,
      point: nil,
      levelId: levelId,
      id: "cotton_shirt")
    equipmentC.put(armor: bodyArmorE, on: .body)
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
      MoveAfterPlayerC(entity: entity, state: .wandering))
    worldModel.statsS.add(component:
      StatsC(entity: entity,
             baseStats: worldModel.csvDB.stats["generic_mob"]!,
             currentStats: nil)).currentStats.fatigue = 0
    worldModel.factionS.add(component: FactionC(entity: entity, faction: "Guards & Scientists"))
    worldModel.forceWaitS.add(component: ForceWaitC(entity: entity))
    let inventoryC = worldModel.inventoryS.add(component: InventoryC(entity: entity))

    let equipmentC = worldModel.equipmentS.add(
      component: EquipmentC(entity: entity))

    if worldModel.mapRNG.get(upperBound: 1) == 1 {
      // Give it some random headgear
      let headgears = worldModel.csvDB.armors.values
        .filter({ $0.slot == EquipmentC.Slot.head.rawValue })
      let headgearE = worldModel.addEntity()
      inventoryC.add(entity: headgearE)
      ArmorAssembly().assemble(
        entity: headgearE,
        worldModel: worldModel,
        point: nil,
        levelId: levelId,
        id: worldModel.mapRNG.choice(headgears).id)
      equipmentC.put(armor: headgearE, on: .head)
    }

    if worldModel.mapRNG.get(upperBound: 1) == 1 {
      // Give it some random gloves
      let gloves = worldModel.csvDB.armors.values
        .filter({ $0.slot == EquipmentC.Slot.hands.rawValue })
      let glovesE = worldModel.addEntity()
      inventoryC.add(entity: glovesE)
      ArmorAssembly().assemble(
        entity: glovesE,
        worldModel: worldModel,
        point: nil,
        levelId: levelId,
        id: worldModel.mapRNG.choice(gloves).id)
      equipmentC.put(armor: glovesE, on: .hands)
    }

    // Give it some random body armor
    let bodyArmors = worldModel.csvDB.armors.values
      .filter({ $0.slot == EquipmentC.Slot.body.rawValue })
    let bodyArmorE = worldModel.addEntity()
    inventoryC.add(entity: bodyArmorE)
    ArmorAssembly().assemble(
      entity: bodyArmorE,
      worldModel: worldModel,
      point: nil,
      levelId: levelId,
      id: worldModel.mapRNG.choice(bodyArmors).id)
    equipmentC.put(armor: bodyArmorE, on: .body)

    let weaponE = worldModel.addEntity()
    // Give it a random weapon
    worldModel.wieldingS.add(entity: entity, component: WieldingC(
      entity: entity,
      weaponEntity: weaponE,
      defaultWeaponDefinition: worldModel.csvDB.weapons["fist"]!))
    inventoryC.add(entity: weaponE)

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
    self.assemble(entity: entity,
                  worldModel: worldModel,
                  point: point,
                  levelId: levelId,
                  id: weaponDef.id)
  }

  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?, id: String) {
    let weaponDef = worldModel.csvDB.weapons[id]!

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


class ArmorAssembly: EntityAssemblyProtocol {
  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?) {
    // TODO: get armor tag from prefab instead of using a constant
    //    guard let levelId = levelId, let level = worldModel.maps[levelId] else { return }
    let tag = "basic"
    let allowedArmors = worldModel.csvDB.armors.values.filter({ $0.tags.contains(tag) })
    let armorDef = worldModel.mapRNG.choice(allowedArmors)
    self.assemble(entity: entity,
                  worldModel: worldModel,
                  point: point,
                  levelId: levelId,
                  id: armorDef.id)
  }

  func assemble(entity: Entity, worldModel: WorldModel, point: BLPoint?, levelId: String?, id: String) {
    let armorDef = worldModel.csvDB.armors[id]!

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
