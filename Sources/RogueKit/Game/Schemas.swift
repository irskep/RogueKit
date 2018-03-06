//
//  Schemas.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/4/18.
//

import Foundation
import BearLibTerminal


protocol Tagged {
  var tags: [String] { get }
}
extension Tagged {
  func matches(_ t: String) -> Bool { return tags.contains(t) }
  func matches(_ t: [String]) -> Bool {
    return tags.contains(where: { t.contains($0) })
  }
}
protocol WeightedChoosable {
  var id: String { get }
  var weight: Double { get }
}


struct WeightedChoice: Codable {
  struct Choice: Codable {
    let value: String
    let weight: Double
  }

  let choices: [Choice]

  init() {
    self.choices = []
  }

  init(string: String) {
    self.choices = string.lowercased().split(separator: ",").map {
      s in
      let items = s.split(separator: ":")
      return Choice(value: String(items[0]), weight: Double(items[1])!)
    }
  }

  init(choices: [Choice]) {
    self.choices = choices
  }

  func choose(rng: RKRNGProtocol) -> String {
    if choices.count == 1 { return choices[0].value }
    guard choices.count > 0 else { fatalError("Can't choose between no options") }
    var mark: Double = 0
    let val = rng.get()
    var maybeValue: String?
    for choice in choices {
      mark += choice.weight
      if val <= mark {
        maybeValue = choice.value
        break
      }
    }
    guard let value = maybeValue else {
      fatalError("Problem with weighted choice code")
    }
    return value
  }

  static func choose<T: WeightedChoosable>(rng: RKRNGProtocol, items: [T]) -> T {
    if items.count == 1 { return items[0] }
    let wc = WeightedChoice(choices: items.map({ Choice(value: $0.id, weight: $0.weight )}))
    let c = wc.choose(rng: rng)
    return items
      .filter({ $0.id == c })
      .first!
  }
}


struct StatBucket: Codable {
  var hp: Double = 0
  var fatigue: Double = 0
//  var speed: Double = 0 // TODO
  var awareness: Double = 0
  var reflex: Double = 0
  var strength: Double = 0
}
func +(_ a: StatBucket, _ b: StatBucket) -> StatBucket {
  return StatBucket(hp: a.hp + b.hp,
                    fatigue: a.fatigue + b.fatigue,
//                    speed: a.speed + b.speed,
                    awareness: a.awareness + b.awareness,
                    reflex: a.reflex + b.reflex,
                    strength: a.strength + b.strength)
}


struct WeaponDefinition: Codable, Tagged, WeightedChoosable {
  let id: String
  let name: String
  let description: String
  let animationId: String
  let tags: [String]
  let weight: Double

  let char: BLInt
  let color: String

  let liters: Double // TODO
  let grams: Double  // TODO

  let strengthRequired: Int

//  let meleeDistance: Int
  let usesRemaining: Int // TODO
  let meleeDamagePhysical: Int // TODO
  let meleeDamageElectric: Int // TODO
  let meleeDamageHeat: Int // TODO
  let rangeDamagePhysical: Int // TODO
  let rangeDamageElectric: Int // TODO
  let rangeDamageHeat: Int // TODO
  let rangeFalloff: Int // TODO
  let rangeMax: Int // TODO

  var isMelee: Bool { return rangeMax == 0 }
  var isRanged: Bool { return !isMelee }
  var damagePhysical: Int { return isMelee ? meleeDamagePhysical : rangeDamagePhysical }
  var damageElectric: Int { return isMelee ? meleeDamageElectric : rangeDamageElectric }
  var damageHeat: Int { return isMelee ? meleeDamageHeat : rangeDamageHeat }

  static let zero = {
    return WeaponDefinition(
      id: "null", name: "null", description: "", animationId: "none", tags: [],
      weight: 0,
      char: CP437.BLOCK, color: "red", liters: 0, grams: 0, strengthRequired: 0,
//      meleeDistance: 0,
      usesRemaining: 0, meleeDamagePhysical: 0,
      meleeDamageElectric: 0, meleeDamageHeat: 0, rangeDamagePhysical: 0,
      rangeDamageElectric: 0, rangeDamageHeat: 0, rangeFalloff: 0, rangeMax: 0)
  }()

  var statsDescription: String {
    var strings: [String] = [
      "\(Int(grams))g, \(liters)L",
      "",
      isMelee ? "Melee weapon" : "Ranged weapon",
      "Requires \(strengthRequired) str",
      ""
    ]
    if usesRemaining > -1 {
      strings.append("\(usesRemaining) uses remaining")
      strings.append("")
    }
    if isRanged {
      strings.append("Loses \(rangeFalloff)% accuracy per tile of distance")
      strings.append("Max range of \(rangeMax) tiles")
      strings.append("")
    }

    strings.append("Damage:")
    if damagePhysical > 0 { strings.append("\(damagePhysical) physical") }
    if damageElectric > 0 { strings.append("\(damageElectric) electric") }
    if damageHeat > 0 { strings.append("\(damageHeat)h(eat)") }
    return strings.joined(separator: "\n")
  }
}


struct ArmorDefinition: Codable, Tagged, WeightedChoosable {
  let id: String
  let name: String
  let char: BLInt
  let color: String
  let description: String
  let liters: Double
  let grams: Double
  let tags: [String]
  let weight: Double
  let slot: String
  let protectionPhysical: Double
  let flammability: Double
  let conductiveness: Double
  let storageLiters: Double

  static let zero = {
    return ArmorDefinition(
      id: "null", name: "null", char: 0, color: "red", description: "", liters: 0,
      grams: 0, tags: [], weight: 0, slot: "null", protectionPhysical: 0, flammability: 0,
      conductiveness: 0, storageLiters: 0)
  }()

  var statsDescription: String {
    var strings: [String] = [
      "\(Int(grams))g, \(liters)L",
      "",
      "Worn on \(slot)",
      ""
    ]
    if protectionPhysical > 0 {
      strings.append("\(Int(protectionPhysical))% physical protection")
    }
    if conductiveness < 100 {
      strings.append("\(Int(100 - conductiveness))% electric protection")
    }
    if flammability < 100 {
      strings.append("\(Int(100 - flammability))% fire protection")
    }
    return strings.joined(separator: "\n")
  }
}


struct ActorDefinition: Codable, Tagged, WeightedChoosable {
  var id: String = ""
  var name: String = ""
  var description: String = ""
  var char: BLInt = 0
  var color: String = ""
  var stats: StatBucket = StatBucket()
  var armorHead: WeightedChoice = WeightedChoice()
  var armorBody: WeightedChoice = WeightedChoice()
  var armorHands: WeightedChoice = WeightedChoice()
  var weapon: WeightedChoice = WeightedChoice()
  var defaultWeapon: String = ""
  var ai: String = ""
  var faction: String = ""
  var tags: [String] = []
  var weight: Double = 0
}


struct PrefabMetadata: Codable, Tagged, WeightedChoosable {
  var id: String
  var tags: [String]
  var weight: Double
  var neighborTags: [String]
  var poiDefinitions: [POIDefinition]

  struct POIDefinition: Codable {
    var char: BLInt
    var kindString: String
    var kind: Kind {
      get { return Kind(rawValue: kindString)! }
      set { kindString = newValue.rawValue }
    }
    var tags: [String]

    enum Kind: String {
      case mob
      case item
    }
  }

  static var data: [PrefabMetadata] = {
    return [
      PrefabMetadata(
        id: "room",
        tags: ["start", "generic"],
        weight: 1,
        neighborTags: ["*"],
        poiDefinitions: []),
      PrefabMetadata(
        id: "oval",
        tags: ["start", "generic"],
        weight: 1,
        neighborTags: ["*"],
        poiDefinitions: []),
      PrefabMetadata(
        id: "jct_+",
        tags: ["start", "generic", "hall"],
        weight: 1,
        neighborTags: ["*"],
        poiDefinitions: []),
      PrefabMetadata(
        id: "jct_-",
        tags: ["start", "generic", "hall"],
        weight: 1,
        neighborTags: ["*"],
        poiDefinitions: []),
      PrefabMetadata(
        id: "jct_|",
        tags: ["start", "generic", "hall"],
        weight: 1,
        neighborTags: ["*"],
        poiDefinitions: []),
    ]
  }()
}
