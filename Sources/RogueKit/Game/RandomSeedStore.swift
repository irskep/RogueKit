//
//  RandomSeedStore.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 1/14/18.
//

import Foundation


class RandomSeedStore: Codable {
  var levelSeeds: [UInt32]

  init(source: RKRNGProtocol, n: Int) {
    levelSeeds = (0..<n).map({ _ in source.get(upperBound: UInt32.max) })
  }

  func getLevelSeed(_ i: Int) -> RKRNGProtocol {
    return RKGetRNG(seed: UInt64(levelSeeds[i]))
  }
}
