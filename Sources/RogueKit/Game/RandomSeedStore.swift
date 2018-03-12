//
//  RandomSeedStore.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 1/14/18.
//

import Foundation


/**
 Store value for multiple PCG32 generators. All share the same seed, but
 use different values for `seq`.

 PCG32 is explicitly designed to allow for uncorrelated RNGs that share a seed.
 By using this feature, we can seed a game with a single RNG and lazily
 instantiate specific RNGs for whatever we want!

 Put another way: when you use PCG32 with a seed, you still have to choose
 which "stream" you want to follow. There are `UInt64.max` streams. This
 class stores separate state for each stream.

 ```
 let store = RandomSeedStore(seed: 1234)

 let rng1 = store["main"]
 let rng2 =
 ```
 */
public class RandomSeedStore: Codable {
  public let seed: UInt64

  private var rngCache = [UInt64: PCG32Generator]()
  private var collisionChecks = [UInt64: String]()

  public init(seed: UInt64) {
    self.seed = seed
  }

  public subscript(index: String) -> PCG32Generator {
    let seq = UInt64(bitPattern: Int64(index.hashValue))
    if let s = collisionChecks[seq], s != index {
      assertionFailure("RandomSeedStore collision between \(s) (existing) and \(index) (new)")
    }
    if collisionChecks[seq] == nil {
      collisionChecks[seq] = index
    }
    return self[seq]
  }

  public subscript(index: UInt64) -> PCG32Generator {
    if let rng = rngCache[index] { return rng }
    let rng = PCG32Generator(seed: seed, seq: index)
    rngCache[index] = rng
    return rng
  }
}
