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
    if t.contains("*") { return true }
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
    guard choices.count > 0 else { fatalError("Can't choose between no choices") }
    if choices.count == 1 { return choices[0].value }
    let weights = choices.map { $0.weight }

    // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
    let sum = weights.reduce(0, +)
    // Random number in the range 0.0 <= rnd < sum :
    let rnd = sum * rng.get()
    // Find the first interval of accumulated probabilities into which `rnd` falls:
    var accum = 0.0
    for (i, p) in weights.enumerated() {
      accum += p
      if rnd < accum {
        return choices[i].value
      }
    }
    print("WARNING: WeightedChoice hit error case")
    return choices.last!.value
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

  func fatigue(forUsingWeapon weapon: WeaponDefinition) -> Double {
    let strReq = Double(weapon.strengthRequired)
    if strength == strReq {
      return 10
    } else if strength > strReq {
      return 10 / (strength - strReq)
    } else {
      let d = (strReq - strength) + 1
      return 10 + d * d
    }
  }
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
  let cooldown: Int
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
      cooldown: 0, meleeDamagePhysical: 0,
      meleeDamageElectric: 0, meleeDamageHeat: 0, rangeDamagePhysical: 0,
      rangeDamageElectric: 0, rangeDamageHeat: 0, rangeFalloff: 0, rangeMax: 0)
  }()

  var statsDescription: String {
    var strings: [String] = [
      "\(Int(grams))g",
//      "",
      isMelee ? "Melee weapon" : "Ranged weapon",
      "Requires \(strengthRequired) str",
      ""
    ]
    if cooldown > 0 {
      strings.append("\(cooldown)-turn cooldown")
      strings.append("")
    }
    if isRanged {
      strings.append("Loses \(rangeFalloff)% accuracy per tile of distance")
      strings.append("Max range of \(rangeMax) tiles")
      strings.append("")
    }

    strings.append("Damage:")
    if damagePhysical > 0 { strings.append("\(damagePhysical)p (physical)") }
    if damageElectric > 0 { strings.append("\(damageElectric)e (electric)") }
    if damageHeat > 0 { strings.append("\(damageHeat)h (heat)") }
    return strings.joined(separator: "\n")
  }

  func statsDescription(onEntityWithStats stats: StatBucket) -> String {
    var strings: [String] = [
      "\(Int(grams))g",
      //      "",
      isMelee ? "Melee weapon" : "Ranged weapon",
      "+\(Int(stats.fatigue(forUsingWeapon: self))) fatigue",
      ""
    ]
    if cooldown > 0 {
      strings.append("\(cooldown)-turn cooldown")
      strings.append("")
    }
    if isRanged {
      strings.append("Loses \(rangeFalloff)% accuracy per tile of distance")
      strings.append("Max range of \(rangeMax) tiles")
      strings.append("")
    }

    strings.append("Damage:")
    if damagePhysical > 0 { strings.append("\(damagePhysical)p (physical)") }
    if damageElectric > 0 { strings.append("\(damageElectric)e (electric)") }
    if damageHeat > 0 { strings.append("\(damageHeat)h (heat)") }
    return strings.joined(separator: "\n")
  }

  func statsDescription(compareTo other: WeaponDefinition, onEntityWithStats stats: StatBucket) -> String {
    var strings: [String] = [
      "\(Int(grams))g",
      //      "",
      isMelee ? "Melee weapon" : "Ranged weapon",
      "+\(Int(stats.fatigue(forUsingWeapon: self))) fatigue",
      S.dim("Current: +\(Int(stats.fatigue(forUsingWeapon: other)))"),
      ""
    ]
    if cooldown > 0 {
      strings.append("\(cooldown)-turn cooldown")
      strings.append(S.dim("Current: \(other.cooldown)"))
      strings.append("")
    }
    if isRanged {
      strings.append("Loses \(rangeFalloff)% accuracy per tile of distance")
      if other.isRanged {
        strings.append(contentsOf: [S.dim("Current: \(other.rangeFalloff)%"), ""])
      }
      strings.append("Max range of \(rangeMax) tiles")
      strings.append(S.dim("Current: \(other.rangeMax)"))
      strings.append("")
    }

    strings.append("Damage:")
    if damagePhysical > 0 || other.damagePhysical > 0 { strings.append("\(damagePhysical)p (physical)") }
    if other.damagePhysical > 0 {
      strings.append(contentsOf: [S.dim("Current: \(other.damagePhysical)p"), ""])
    }
    if damageElectric > 0 || other.damageElectric > 0 { strings.append("\(damageElectric)e (electric)") }
    if other.damageElectric > 0 {
      strings.append(contentsOf: [S.dim("Current: \(other.damageElectric)e"), ""])
    }
    if damageHeat > 0 || other.damageHeat > 0 { strings.append("\(damageHeat)h (heat)") }
    if other.damageHeat > 0 {
      strings.append(contentsOf: [S.dim("Current: \(other.damageHeat)h"), ""])
    }
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
      grams: 0, tags: [], weight: 0, slot: "null", protectionPhysical: 0, flammability: 100,
      conductiveness: 100, storageLiters: 0)
  }()

  var statsDescription: String {
    var strings: [String] = [
      "\(Int(grams))g",
//      "",
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
      strings.append("\(Int(100 - flammability))% heat protection")
    }
    return strings.joined(separator: "\n")
  }

  func statsDescription(in worldModel: WorldModel, comparedTo armorDefinition: ArmorDefinition?) -> String {
    let armorDef = armorDefinition ?? ArmorDefinition.zero
    var strings: [String] = [
      "\(Int(grams))g",
//      "",
      "Worn on \(slot)",
      ""
    ]
    if protectionPhysical > 0 || armorDef.protectionPhysical > 0 {
      strings.append("\(Int(protectionPhysical))% physical protection")
      strings.append(S.dim("(current: \(Int(armorDef.protectionPhysical))%)"))
      strings.append("")
    }
    if conductiveness < 100 || armorDef.conductiveness < 100 {
      strings.append("\(Int(100 - conductiveness))% electric protection")
      strings.append(S.dim("(current: \(Int(100 - armorDef.conductiveness))%)"))
      strings.append("")
    }
    if flammability < 100 || armorDef.flammability < 100 {
      strings.append("\(Int(100 - flammability))% heat protection")
      strings.append(S.dim("(current: \(Int(100 - armorDef.flammability))%)"))
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
  var maxPorts: Int
  var maxInstances: Int
  var hasDoors: Bool
  var neighborTags: [String]
  var description: String
  var poiDefinitions: [POIDefinition]

  struct POIDefinition: Codable {
    var code: BLInt
    var kindString: String
    var kind: Kind {
      get { return Kind(rawValue: kindString)! }
      set { kindString = newValue.rawValue }
    }
    var tags: [String]
    var isRequired: Bool

    enum Kind: String {
      case mob
      case item
      case armor
      case weapon
      case entrance
      case exit
      case stim
    }

    init(code: BLInt, kind: Kind, tags: [String], isRequired: Bool) {
      self.code = code
      self.kindString = kind.rawValue
      self.tags = tags
      self.isRequired = isRequired
    }
  }

  static var zero: PrefabMetadata = {
    return PrefabMetadata(
      id: "NO METADATA",
      tags: [],
      weight: 0,
      maxPorts: -1,
      maxInstances: -1,
      hasDoors: false,
      neighborTags: ["*"],
      description: "",
      poiDefinitions: [])
  }()

  static func poiDefs(_ tags: [String]) -> [PrefabMetadata.POIDefinition] {
    return [
      POIDefinition(
        code: BLInt(CP437.char(for: "m")),
        kind: .mob,
        tags: tags,
        isRequired: false),
      POIDefinition(
        code: BLInt(CP437.char(for: "M")),
        kind: .mob,
        tags: tags,
        isRequired: true),
      POIDefinition(
        code: BLInt(CP437.char(for: "i")),
        kind: .item,
        tags: tags,
        isRequired: false),
      POIDefinition(
        code: BLInt(CP437.char(for: "I")),
        kind: .item,
        tags: tags,
        isRequired: true),
      POIDefinition(
        code: BLInt(CP437.char(for: "e")),
        kind: .entrance,
        tags: tags,
        isRequired: false),
      POIDefinition(
        code: BLInt(CP437.char(for: "E")),
        kind: .entrance,
        tags: tags,
        isRequired: true),
      POIDefinition(
        code: BLInt(CP437.char(for: "x")),
        kind: .exit,
        tags: tags,
        isRequired: false),
      POIDefinition(
        code: BLInt(CP437.char(for: "X")),
        kind: .exit,
        tags: tags,
        isRequired: true),
      POIDefinition(
        code: BLInt(CP437.char(for: "s")),
        kind: .stim,
        tags: tags,
        isRequired: false),
      ]
  }
}
