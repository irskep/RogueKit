//
//  StringUtils.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/4/18.
//

import Foundation
import BearLibTerminal


private extension ActorC {
  var description: String {
    let hpBar = StringUtils.statBar(
      width: MENU_W - 2,
      label: "HP",
      labelColor: "ui_text",
      barText: "\(Int(currentStats.hp))/\(Int(definition.stats.hp))",
      barFraction: currentStats.hp / definition.stats.hp,
      barColorThresholds: [
        (0.0, "ui_text", "red", "darkpurple"),
        (0.5, "ui_text", "green", "darkgreen"),
      ])

    let fatigueBar = StringUtils.statBar(
      width: MENU_W - 2,
      label: "Fatigue",
      labelColor: "ui_text",
      barText: "\(Int(currentStats.fatigue))/\(Int(definition.stats.fatigue))",
      barFraction: currentStats.fatigue / definition.stats.fatigue,
      barColorThresholds: [
        (0.0, "ui_text", "teal", "darkblue"),
        (0.75, "ui_text", "orange", "darkpurple"),
        (0.9, "ui_text", "red", "darkpurple"),
        ])
    return """
      \(hpBar)[bkcolor=ui_bg]
      \(fatigueBar)[bkcolor=ui_bg]
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


  class func statBar(
    width: BLInt,
    label: String,
    labelColor: String,
    barText: String,
    barFraction: Double,
    barColorThresholds: [(Double, String, String, String)])
    -> String
  {
    var strings: [String] = ["[color=\(labelColor)]", label, ": "]
    let w = width - BLInt(label.count + 2)
    let barMaxX = BLInt((Double(w) * barFraction).rounded())
    var fg = barColorThresholds.last!.1
    var bg = barColorThresholds.last!.2
    var bg2 = barColorThresholds.last!.3
    for i in 0..<(barColorThresholds.count - 1) {
      if barColorThresholds[i].0 <= barFraction && barColorThresholds[i + 1].0 > barFraction {
        fg = barColorThresholds[i].1
        bg = barColorThresholds[i].2
        bg2 = barColorThresholds[i].3
        break
      }
    }
    strings.append("[color=\(fg)][bkcolor=\(bg)]")
    let t = barText.rightPad(Int(w), " ")
    let partition = t.index(t.startIndex, offsetBy: String.IndexDistance(barMaxX))
    strings.append(String(t[t.startIndex..<partition]))
    strings.append("[bkcolor=\(bg2)]")
    strings.append(String(t[partition..<t.endIndex]))
    strings.append("[/bkcolor]")
    return strings.joined()
  }
}
