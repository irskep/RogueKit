//
//  StringUtils.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/4/18.
//

import Foundation
import BearLibTerminal


private extension StatBucket {
  var description: String { return """
    HP: \(Int(hp))
    Fatigue: \(Int(fatigue))
    Reflex: \(Int(reflex))
    Strength: \(Int(strength))
    """.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
}


class StringUtils {
  class func describe(
    entity: Entity,
    in worldModel: WorldModel,
    showName: Bool,
    showWeaponDescription: Bool)
    -> String
  {
    var strings = [String]()
    if showName, let nameC = worldModel.nameS[entity] {
      strings.append(contentsOf: [nameC.name, "", nameC.description])
    }
    if let statsString = worldModel.statsS[entity]?.currentStats.description {
      strings.append(contentsOf: ["", statsString])
    }
    if let weaponDef: WeaponDefinition = worldModel.weapon(wieldedBy: entity) {
      strings.append(contentsOf: ["", "Wielding: \(weaponDef.name)"])
      if showWeaponDescription {
        strings.append("(\(weaponDef.description))")
      }
    }
    if let equipmentC = worldModel.equipmentS[entity] {
      strings.append("")
      for slot in EquipmentC.Slot.all {
        let value = equipmentC.armor(on: slot, in: worldModel)?.armorDefinition.name ?? "none"
        strings.append("\(slot): \(value)")
      }
    }

    if entity != worldModel.player,
      let prediction = worldModel.predictFight(attacker: worldModel.player, defender: entity)
    {
      strings.append(contentsOf: ["", "Fight:", prediction.humanDescription])
    }

    return strings.joined(separator: "\n")
  }
}
