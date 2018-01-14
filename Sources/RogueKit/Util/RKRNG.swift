//
//  RKRNG.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/10/18.
//

import Foundation

public protocol RKRNGProtocol {
  func get(upperBound: UInt32) -> UInt32
  func choice<T>(_ array: [T]) -> T
  func shuffleInPlace<T>(_ array: inout [T])
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
  public class RKGameKitRNG: RKRNGProtocol {
    private let _rng: GKRandom
    init(rng: GKRandom) {
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
  }
#endif
