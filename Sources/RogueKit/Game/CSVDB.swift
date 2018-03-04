//
//  CSVDB.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


struct WeaponDefinition {
  let id: String
  let name: String
  let description: String
  let animationId: String
  let tags: [String]

  let char: BLInt
  let color: String

  let liters: Double
  let grams: Double

  let meleeDistance: Int
  let usesRemaining: Int
  let meleeDamagePhysical: Int
  let meleeDamageElectric: Int
  let meleeDamageHeat: Int
  let rangeDamagePhysical: Int
  let rangeDamageElectric: Int
  let rangeDamageHeat: Int
  let rangeFalloff: Int
  let rangeMax: Int
}


class CSVDB {
  let resources: ResourceCollectionProtocol

  lazy var stats: [String: StatBucket] = { _createStatsDB() }()

  lazy var weapons: [String: WeaponDefinition] = { _createWeaponsDB() }()

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  private func _createStatsDB() -> [String: StatBucket] {
    do {
      return try resources.csvMap(name: "stats_etc", mapper: {
        (row: StringBox) -> (String, StatBucket) in
        return (row["id"], StatBucket(
          hp: row["hp"],
          fatigue: row["fatigue"],
          speed: row["speed"],
          awareness: row["awareness"],
          reflex: row["reflex"],
          strength: row["strength"]))
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
          meleeDistance: row["melee_dist"],
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
}
