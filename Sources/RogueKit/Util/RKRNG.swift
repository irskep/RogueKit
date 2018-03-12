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

public func RKGetRNG(seed: UInt64) -> RKRNGProtocol {
  return PCG32Generator(seed: seed, seq: 0)
}
