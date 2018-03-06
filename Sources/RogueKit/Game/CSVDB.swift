//
//  CSVDB.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


class CSVDB {
  let resources: ResourceCollectionProtocol

  lazy var actors: [String: ActorDefinition] = { _createActorsDB() }()
  lazy var weapons: [String: WeaponDefinition] = { _createWeaponsDB() }()
  lazy var armors: [String: ArmorDefinition] = { _createArmorDB() }()

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  private func _createActorsDB() -> [String: ActorDefinition] {
    do {
      return try resources.csvMap(name: "stats_etc", mapper: {
        (row: StringBox) -> (String, ActorDefinition) in
        let stats = StatBucket(
          hp: row["hp"],
          fatigue: row["fatigue"],
          //          speed: row["speed"],
          awareness: row["awareness"],
          reflex: row["reflex"],
          strength: row["strength"])
        return (row["id"], ActorDefinition(
          id: row["id"],
          stats: stats,
          armorHead: WeightedChoice(string: row["armor_head"]),
          armorBody: WeightedChoice(string: row["armor_body"]),
          armorHands: WeightedChoice(string: row["armor_hands"]),
          weapon: WeightedChoice(string: row["weapon"]),
          defaultWeapon: row["default_weapon"],
          ai: row["ai"]))
      })
    } catch {
      fatalError("Could not load stats_etc.csv")
    }
  }

  private func _createWeaponsDB() -> [String: WeaponDefinition] {
    do {
      return try resources.csvMap(name: "weapons", mapper: {
        (row: StringBox) -> (String, WeaponDefinition) in

        var meleeDamage = [String: Int]()
        for s in row.string("melee_damage_types").lowercased().split(separator: ",") {
          let items = s.split(separator: ":")
          meleeDamage[String(items[0])] = Int(items[1])
        }

        var rangeDamage = [String: Int]()
        for s in row.string("ranged_damage_types").lowercased().split(separator: ",") {
          let items = s.split(separator: ":")
          rangeDamage[String(items[0])] = Int(items[1])
        }

        return (row["id"], WeaponDefinition(
          id: row["id"],
          name: row["name"],
          description: row["description"],
          animationId: row["animation_id"],
          tags: row.string("tags").split(separator: ",").map({ String($0) }),
          char: BLInt(row.int("char")),
          color: row["color"],
          liters: row["liters"],
          grams: row["grams"],
          strengthRequired: row["strength_required"],
//          meleeDistance: row["melee_dist"],
          usesRemaining: row["uses_remaining"],
          meleeDamagePhysical: meleeDamage["physical"] ?? 0,
          meleeDamageElectric: meleeDamage["electric"] ?? 0,
          meleeDamageHeat: meleeDamage["heat"] ?? 0,
          rangeDamagePhysical: rangeDamage["physical"] ?? 0,
          rangeDamageElectric: rangeDamage["electric"] ?? 0,
          rangeDamageHeat: rangeDamage["heat"] ?? 0,
          rangeFalloff: row["range_falloff"],
          rangeMax: row["range_max"]))
      })
    } catch {
      fatalError("Could not load weapons")
    }
  }

  private func _createArmorDB() -> [String: ArmorDefinition] {
    do {
      return try resources.csvMap(name: "armor", mapper: {
        (row: StringBox) -> (String, ArmorDefinition) in

        return (row["id"], ArmorDefinition(
          id: row["id"],
          name: row["name"],
          char: BLInt(row.int("char")),
          color: row["color"],
          description: row["description"],
          liters: row["liters"],
          grams: row["grams"],
          tags: row.string("tags").split(separator: ",").map({ String($0) }),
          slot: row["slot"],
          protectionPhysical: row["protection_physical"],
          flammability: row["flammability"],
          conductiveness: row["conductiveness"],
          storageLiters: row["storage_liters"]))
      })
    } catch {
      fatalError("Could not load armor")
    }
  }
}
