//
//  CSVDB.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


class CSVDB {
  weak var resources: ResourceCollectionProtocol!

  lazy var mapDefinitions: [MapDefinition] = { _createMapDefinitionDB() }()
  lazy var prefabs: [String: PrefabMetadata] = { _createPrefabDB() }()
  lazy var actors: [String: ActorDefinition] = { _createActorsDB() }()
  lazy var weapons: [String: WeaponDefinition] = { _createWeaponsDB() }()
  lazy var armors: [String: ArmorDefinition] = { _createArmorDB() }()

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  func actors(matching t: String) -> [ActorDefinition] { return actors.values.filter({ $0.matches(t) })}
  func weapons(matching t: String) -> [WeaponDefinition] { return weapons.values.filter({ $0.matches(t) })}
  func armors(matching t: String) -> [ArmorDefinition] { return armors.values.filter({ $0.matches(t) })}
  func actors(matching t: [String]) -> [ActorDefinition] { return actors.values.filter({ $0.matches(t) })}
  func weapons(matching t: [String]) -> [WeaponDefinition] { return weapons.values.filter({ $0.matches(t) })}
  func armors(matching t: [String]) -> [ArmorDefinition] { return armors.values.filter({ $0.matches(t) })}

  private func _createMapDefinitionDB() -> [MapDefinition] {
    do {
      return try resources.csv(name: "maps", mapper: {
        (row: StringBox) -> (MapDefinition) in
        var exits = [String: String]()
        if let v = row.maybeString("previous") { exits["previous"] = v }
        if let v = row.maybeString("next") { exits["next"] = v }
        return MapDefinition(
          id: row["id"],
          generatorId: row["script"],
          tagWhitelist: row.stringList("tag_whitelist"),
          numItems: row["num_items"],
          numMobs: row["num_mobs"],
          numStims: row["num_stims"],
          text: row["text"],
          exits: exits)
      })
    } catch {
      fatalError("Could not load stats_etc.csv")
    }
  }

  private func _createPrefabDB() -> [String: PrefabMetadata] {
    var last: PrefabMetadata!
    do {
      return try resources.csvMap(name: "prefabs", mapper: {
        (row: StringBox) -> (String, PrefabMetadata) in

        let id: String = row["id"]
        let weight: Double = row.isQuotes("weight") ? last.weight : row["weight"]
        let maxPorts: Int = row.isQuotes("max_ports") ? last.maxPorts : row["max_ports"]
        let hasDoors: Bool = row.isQuotes("has_doors") ? last.hasDoors : row["has_doors"]
        let maxInstances: Int = row.isQuotes("max_instances") ? last.maxInstances : row["max_instances"]
        let tags = row.isQuotes("tags")
          ? last.tags
          : row.string("tags").lowercased().split(separator: ",").map { String($0) }
        let neighborTags = row.isQuotes("neighbor_tags")
          ? last.neighborTags
          : row.string("neighbor_tags").lowercased().split(separator: ",").map { String($0) }
        let poiTags = row.isQuotes("poi_tags")
          ? last.poiDefinitions.first!.tags  // unsafe but ok for 7drl
          : row.string("poi_tags").lowercased().split(separator: ",").map { String($0) }

        let m = PrefabMetadata(
          id: id, tags: tags, weight: weight, maxPorts: maxPorts, maxInstances: maxInstances,
          hasDoors: hasDoors, neighborTags: neighborTags,
          description: row["description"],
          poiDefinitions: PrefabMetadata.poiDefs(poiTags))
        last = m
        return (id, m)
      })
    } catch {
      fatalError("Could not load stats_etc.csv")
    }
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
          name: row["name"],
          description: row["description"],
          char: BLInt(row.int("char")),
          color: row["color"],
          stats: stats,
          armorHead: WeightedChoice(string: row["armor_head"]),
          armorBody: WeightedChoice(string: row["armor_body"]),
          armorHands: WeightedChoice(string: row["armor_hands"]),
          weapon: WeightedChoice(string: row["weapon"]),
          defaultWeapon: row["default_weapon"],
          ai: row["ai"],
          faction: row["faction"],
          tags: row.string("tags").split(separator: ",").map({ String($0) }),
          weight: row["weight"]))
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
          weight: row["weight"],
          char: BLInt(row.int("char")),
          color: row["color"],
          liters: row["liters"],
          grams: row["grams"],
          strengthRequired: row["strength_required"],
//          meleeDistance: row["melee_dist"],
          cooldown: row["cooldown"],
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
          weight: row["weight"],
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
