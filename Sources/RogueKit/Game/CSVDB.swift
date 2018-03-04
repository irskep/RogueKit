//
//  CSVDB.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/3/18.
//

import Foundation
import BearLibTerminal


class CSVDB {
  let resources: ResourceCollectionProtocol

  lazy var stats: [String: StatBucket] = { _createStatsDB() }()

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
}
