//
//  RKRNG.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/10/18.
//

import Foundation

public protocol RKRNGProtocol: Codable {
  func get(upperBound: UInt32) -> UInt32
  func choice<T>(_ array: [T]) -> T
  func shuffleInPlace<T>(_ array: inout [T])
}

extension RKRNGProtocol {
  func get() -> Double {
    return Double(self.get(upperBound: UInt32.max)) / Double(UInt32.max)
  }
}

public class RKRNG: RKRNGProtocol {
  public func get(upperBound: UInt32) -> UInt32 {
    return arc4random_uniform(upperBound)
  }

  public func choice<T>(_ array: [T]) -> T {
    if array.count < 1 { fatalError("Tried to choose from an array of nothing") }
    let index = self.get(upperBound: UInt32(array.count))
    return array[Int(index)]
  }

  public func shuffleInPlace<T>(_ array: inout [T]) {
    if array.count <= 1 { return }

    for i in 0..<array.count - 1 {
      #if os(Linux)
        let j = Int(random() % (array.count - i)) + i
      #else
        let j = Int(get(upperBound: UInt32(array.count - i))) + i
      #endif
      if i == j { continue }
      array.swapAt(i, j)
    }
  }
}

#if os(OSX) || os(iOS)
  import GameKit
  @available(OSX 10.11, *)
  public class RKGameKitRNG: RKRNGProtocol {
    private let _rng: GKRandomSource

    init(rng: GKRandomSource) {
      _rng = rng
    }

    public func get(upperBound: UInt32) -> UInt32 {
      return UInt32(_rng.nextInt(upperBound: Int(upperBound)))
    }

    public func choice<T>(_ array: [T]) -> T {
      if array.count < 1 { fatalError("Tried to choose from an array of nothing") }
      let index = self.get(upperBound: UInt32(array.count))
      return array[Int(index)]
    }

    public func shuffleInPlace<T>(_ array: inout [T]) {
      if array.count <= 1 { return }

      for i in 0..<array.count - 1 {
        let j = Int(get(upperBound: UInt32(array.count - i))) + i
        if i == j { continue }
        array.swapAt(i, j)
      }
    }

    enum CodingKeys: String, CodingKey {
      case _rng
    }

    public func encode(to encoder: Encoder) throws {
    }

    public required init(from decoder: Decoder) throws {
      print("WARNING: ignoring all random seeds")
      _rng = GKMersenneTwisterRandomSource()
    }
  }
#endif

public func RKGetRNG(seed: UInt64) -> RKRNGProtocol {
  return PCG32Generator(seed: seed, seq: 0)
}
