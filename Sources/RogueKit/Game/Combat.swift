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
  let isExhausted: Bool
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
  var fatigueDelta: Double = 0

  // sums to 1
  var slotChances: [EquipmentC.Slot: Double] = [.head: 0.25, .hands: 0.1, .body: 1 - 0.35]

  var slotDamageAmounts = [EquipmentC.Slot: [DamageType: Double]]()

//  var slotFlammabilityChances = [String: Double]()

  var humanDescription: String {
    var strings: [String] = [
      """
      Fatigue:          +\(Int(fatigueDelta))
      Final hit chance: [color=ui_text]\(_pct(hitChance))
      [color=ui_text_dim]Fatigue:          [color=ui_text]\(Int(fatigueDelta))
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
  // attacker stat delta
  case miss(StatBucket)
  // slot hit, attacker stat delta, defender stat delta, dmg summary string
  case changeStats(String, StatBucket, StatBucket, String)
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

    var defenderReflex: Double = _100(defender.stats.reflex)
    if defender.isExhausted {
      defenderReflex /= 2
    }
    let defenderBaseDodgeChance = 0.05 + (1 - defenderReflex * 0.95)

    let strReq = Double(attacker.weapon.strengthRequired)
    if attacker.stats.strength == strReq {
      stats.fatigueDelta = 10
    } else if attacker.stats.strength > strReq {
      stats.fatigueDelta = 10 / (attacker.stats.strength - strReq)
    } else {
      let d = (strReq - attacker.stats.strength) + 1
      stats.fatigueDelta = 10 + d * d
    }

    if attacker.weapon.isMelee {
      stats.baseHitChance = 1
      stats.hitChance = defenderBaseDodgeChance
      if attacker.position.manhattanDistance(to: defender.position) > 1 && !forUI {
        stats.hitChance = 0  // too far!
      }
    } else {
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
    let didHit = rng.get() <= stats.hitChance
    if stats.hitChance == 0 || !didHit {
      return [.miss(StatBucket(
        hp: 0, fatigue: stats.fatigueDelta, awareness: 0, reflex: 0, strength: 0))]
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
      let defenderStats = StatBucket(
        hp: -finalAmount, fatigue: 0, awareness: 0, reflex: 0, strength: 0)
      let attackerStats = StatBucket(
        hp: 0, fatigue: stats.fatigueDelta, awareness: 0, reflex: 0, strength: 0)
      let damageSummaryStrings: [String] = Array(stats.slotDamageAmounts[slot]!
        .filter({ $1 > 0 })
        .map({
          (arg: (key: CombatStats.DamageType, value: Double)) -> String in
          let (k, v) = arg
          return "\(Int(v))\(k.rawValue.first!)"
        }))

      return [.changeStats(
        slot.rawValue,
        attackerStats, defenderStats,
        damageSummaryStrings.isEmpty ? "no damage" : damageSummaryStrings.joined(separator: ","))]
    }
  }
}
