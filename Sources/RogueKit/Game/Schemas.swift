//
//  Schemas.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/4/18.
//

import Foundation
import BearLibTerminal


struct StatBucket: Codable {
  var hp: Double = 0
  var fatigue: Double = 0 // TODO
  var speed: Double = 0 // TODO
  var awareness: Double = 0 // TODO
  var reflex: Double = 0  // TODO
  var strength: Double = 0
}
func +(_ a: StatBucket, _ b: StatBucket) -> StatBucket {
  return StatBucket(hp: a.hp + b.hp,
                    fatigue: a.fatigue + b.fatigue,
                    speed: a.speed + b.speed,
                    awareness: a.awareness + b.awareness,
                    reflex: a.reflex + b.reflex,
                    strength: a.strength + b.strength)
}


struct WeaponDefinition: Codable {
  let id: String
  let name: String
  let description: String
  let animationId: String
  let tags: [String]

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

  var isMelee: Bool { return rangeMax <= 0 }
  var isRanged: Bool { return !isMelee }
  var damagePhysical: Int { return isMelee ? meleeDamagePhysical : rangeDamagePhysical }
  var damageElectric: Int { return isMelee ? meleeDamageElectric : rangeDamageElectric }
  var damageHeat: Int { return isMelee ? meleeDamageHeat : rangeDamageHeat }

  static let zero = {
    return WeaponDefinition(
      id: "null", name: "null", description: "", animationId: "none", tags: [],
      char: CP437.BLOCK, color: "red", liters: 0, grams: 0, strengthRequired: 0,
//      meleeDistance: 0,
      usesRemaining: 0, meleeDamagePhysical: 0,
      meleeDamageElectric: 0, meleeDamageHeat: 0, rangeDamagePhysical: 0,
      rangeDamageElectric: 0, rangeDamageHeat: 0, rangeFalloff: 0, rangeMax: 0)
  }()
}


struct ArmorDefinition: Codable {
  let id: String
  let name: String
  let char: BLInt
  let color: String
  let description: String
  let liters: Double
  let grams: Double
  let tags: [String]
  let slot: String
  let protectionPhysical: Double
  let flammability: Double
  let conductiveness: Double
  let storageLiters: Double

  static let zero = {
    return ArmorDefinition(
      id: "null", name: "null", char: 0, color: "red", description: "", liters: 0,
      grams: 0, tags: [], slot: "null", protectionPhysical: 0, flammability: 0,
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
    if conductiveness > 0 {
      strings.append("\(Int(100 - conductiveness))% electric protection")
    }
    if flammability > 0 {
      strings.append("\(Int(100 - flammability))% fire protection")
    }
    return strings.joined(separator: "\n")
  }
}
