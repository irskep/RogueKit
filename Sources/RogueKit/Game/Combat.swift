//
//  Combat.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/4/18.
//

import Foundation
import BearLibTerminal


extension String {
  func rightPad(_ n: Int, _ s: String) -> String {
    return self.padding(toLength: n, withPad: " ", startingAt: s.count - 1)
  }
}


let DAMAGE_SCALE: Double = 100


struct Combatant {
  let position: BLPoint
  let weapon: WeaponDefinition
  let equipment: [String: ArmorC]
  let stats: StatBucket
}


struct CombatStats {
  // All doubles are 0-1 unless otherwise specified

  enum DamageType: String {
    case physical
    case electric
    case heat

    static var all: [DamageType] { return [.physical, .electric, .heat] }
  }

  var baseHitChance: Double = 0
  var hitChance: Double = 0
  var strengthDifference: Double = 0
  var fatigueDelta: Double = 0

  // sums to 1
  var slotChances: [EquipmentC.Slot: Double] = [.head: 0.25, .hands: 0.1, .body: 1 - 0.35]

  var slotDamageAmounts = [EquipmentC.Slot: [DamageType: Double]]()

//  var slotFlammabilityChances = [String: Double]()

  var humanDescription: String {
    var strings: [String] = [
      """
      [color=ui_text_dim]Base hit chance:  \(_pct(baseHitChance))
      Strength diff:    \(Int(strengthDifference))
      Final hit chance: [color=ui_text]\(_pct(hitChance))
      """.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    ]

    for slot in EquipmentC.Slot.all {
      let dmgs = slotDamageAmounts[slot]!
      let slotChance = slotChances[slot]!
      let prefix = "\(slot.rawValue.rightPad(5, " ")) (\(_pct(slotChance))): "
      strings.append("[color=ui_text_dim]\(prefix)[color=ui_text]" + DamageType.all.flatMap({
        guard dmgs[$0]! > 0 else { return nil }
        return "\(Int(dmgs[$0]!))\($0.rawValue.first!)"
      }).joined(separator: ","))
    }

    return strings.joined(separator: "\n")
  }
}

enum CombatOutcome {
  case miss
  case changeStats(String, StatBucket, String) // slot hit, stat delta, dmg summary string
//  case equipmentCatchFire(String)  // slot
//  case combatantCatchFire
}


func _100(_ val: Int) -> Double { return Double(val) / 100 }
func _100(_ val: Double) -> Double { return val / 100 }
func _distance(_ a: BLPoint, _ b: BLPoint) -> Double {
  let d1 = Double(a.x - b.x)
  let d2 = Double(a.y - b.y)
  return sqrt(d1 * d1 + d2 * d2)
}
func _pct(_ val: Double) -> String {
  return "\(Int(floor(val * 100)))%"
}


extension CombatStats {
  static func predictFight(attacker: Combatant, defender: Combatant, forUI: Bool = false) -> CombatStats {
    var stats = CombatStats()


    let distance = _distance(attacker.position, defender.position)

    let defenderReflex: Double = _100(defender.stats.reflex)
    let defenderBaseDodgeChance = 0.05 + (1 - defenderReflex * 0.95)

    stats.strengthDifference = (
      attacker.stats.strength
        - Double(attacker.weapon.strengthRequired))

    stats.fatigueDelta = 10 - attacker.stats.strength - stats.strengthDifference

    if attacker.weapon.isMelee {
      stats.baseHitChance = 1
      stats.hitChance = defenderBaseDodgeChance
      if distance > 1 && !forUI {
        stats.hitChance = 0  // too far!
      }
    } else {
      stats.strengthDifference = min(0,  stats.strengthDifference)
      if distance > Double(attacker.weapon.rangeMax) &&
        attacker.weapon.rangeMax > 0
      {
        stats.baseHitChance = 0
        stats.hitChance = 0
      } else {
        stats.baseHitChance = 1.0 - _100(attacker.weapon.rangeFalloff) * distance
        if distance == 1 {  // "too close" is a special case; 50% nerf
          stats.baseHitChance /= 2
        }
        stats.hitChance = stats.baseHitChance * defenderBaseDodgeChance
      }
    }

    for slot in EquipmentC.Slot.all {
      let protection = _100(
        defender.equipment[slot.rawValue]?.armorDefinition.protectionPhysical ?? 0)
      let conductiveness = _100(
        defender.equipment[slot.rawValue]?.armorDefinition.conductiveness ?? 100)
      let flammability = _100(
        defender.equipment[slot.rawValue]?.armorDefinition.flammability ?? 100)
      stats.slotDamageAmounts[slot] = [
        CombatStats.DamageType.physical: _100(attacker.weapon.damagePhysical) * (1 - protection) * DAMAGE_SCALE,
        CombatStats.DamageType.electric: _100(attacker.weapon.damageElectric) * conductiveness * DAMAGE_SCALE,
        CombatStats.DamageType.heat: _100(attacker.weapon.damageHeat) * flammability * DAMAGE_SCALE,
      ]
    }

    return stats
  }

  static func fight(rng: RKRNGProtocol, stats: CombatStats) -> [CombatOutcome] {
    if rng.get() > stats.hitChance {
      return [.miss]
    } else {
      // Weighted random choice of slot chances
      var mark: Double = 0
      let val = rng.get()
      var maybeSlot: EquipmentC.Slot?
      for (k, v) in stats.slotChances {
        mark += v
        if val <= mark {
          maybeSlot = k
          break
        }
      }
      guard let slot = maybeSlot else {
        fatalError("Problem with weighted choice code")
      }
      let finalAmount = stats.slotDamageAmounts[slot]!.values.reduce(0, +)
      var finalStats = StatBucket()
      finalStats.hp = -finalAmount
      finalStats.fatigue = stats.fatigueDelta
      let damageSummaryStrings: [String] = Array(stats.slotDamageAmounts[slot]!
        .filter({ $1 > 0 })
        .map({
          (arg: (key: CombatStats.DamageType, value: Double)) -> String in
          let (k, v) = arg
          return "\(Int(v))\(k.rawValue.first!)"
        }))

      return [.changeStats(
        slot.rawValue,
        finalStats,
        damageSummaryStrings.isEmpty ? "no damage" : damageSummaryStrings.joined(separator: ","))]
    }
  }
}
