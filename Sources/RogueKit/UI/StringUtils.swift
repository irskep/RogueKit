//
//  StringUtils.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/4/18.
//

import Foundation
import BearLibTerminal


private extension ActorC {
  var description: String { return """
    HP: \(Int(currentStats.hp))/\(Int(definition.stats.hp))
    Fatigue: \(Int(currentStats.fatigue))/\(Int(definition.stats.fatigue))
    Reflex: \(Int(currentStats.reflex))
    Strength: \(Int(currentStats.strength))
    """.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
}


class S {
  static func dim(_ s: String) -> String {
    return "[color=ui_text_dim]" + s + "[/color]"
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
      strings.append(contentsOf: [
        nameC.name, "", S.dim(nameC.description)])
    }
    if let actorString = worldModel.actorS[entity]?.description {
      strings.append(contentsOf: ["", actorString])
    }
    if let weaponDef: WeaponDefinition = worldModel.weapon(wieldedBy: entity) {
      strings.append(contentsOf: ["", "\(S.dim("Wielding:")) \(weaponDef.name)"])
      if showWeaponDescription {
        strings.append(S.dim("(\(weaponDef.description))"))
        strings.append(weaponDef.statsDescription)
      }
    }
    if let armor = worldModel.armorS[entity]?.armorDefinition {
      strings.append("")
      strings.append(armor.statsDescription)
    }
    if let weapon = worldModel.weaponS[entity]?.weaponDefinition {
      strings.append("")
      strings.append(weapon.statsDescription)
    }
    if let equipmentC = worldModel.equipmentS[entity] {
      strings.append("")
      for slot in EquipmentC.Slot.all {
        let value = equipmentC.armor(on: slot, in: worldModel)?.armorDefinition.name
          ?? S.dim("none")
        strings.append("\(S.dim("\(slot):")) \(value)")
      }
    }

    if entity != worldModel.player {
      if let prediction = worldModel.predictFight(attacker: worldModel.player, defender: entity, forUI: true) {
        strings.append(contentsOf: ["", "You attack them:", prediction.humanDescription])
      }
      if let prediction = worldModel.predictFight(attacker: entity, defender: worldModel.player, forUI: true) {
        strings.append(contentsOf: ["", "They attack you:", prediction.humanDescription])
      }
    }

    return strings.joined(separator: "\n")
  }
}
