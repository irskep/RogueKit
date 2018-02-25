//
//  PCG32.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 2/25/18.
//
//  Reference: https://github.com/imneme/pcg-c-basic/blob/master/pcg_basic.c
//  For additional information about the PCG random number generation scheme,
//  including its license and other licensing options, visit
//  http://www.pcg-random.org

import Foundation


public class PCG32Generator: Codable {
    var state: UInt64 = 0
    var inc: UInt64

    static var `default`: PCG32Generator = {
        return PCG32Generator(seed: 0x853c49e6748fea9b, seq: 0xda3e39cb94b95bdb)
    }()

    init(seed: UInt64, seq: UInt64) {
        inc = (seq << 1) | 1
        _ = advance()
        state += seed
        _ = advance()
    }

    private func advance() -> UInt32 {
        let oldState = state
        state = oldState &* 6364136223846793005 &+ inc;

        // Calculate output function (XSH RR)
        let xorshifted = UInt32(truncatingIfNeeded: ((oldState >> 18) ^ oldState) >> 27);
        let rot = UInt32(truncatingIfNeeded: oldState >> 59);
        return (xorshifted >> rot) | (xorshifted << UInt32((-Int32(rot)) & 31));
    }

    public func get(upperBound: UInt32) -> UInt32 {
        if upperBound == UInt32.max { return advance() }

        // Original C expression: -upperBound % upperBound
        // But we can't do that in Swift.
        // What `-` actually means on a uint32 in C is "maxValue - value + 1".
        // https://stackoverflow.com/questions/8026694/c-unary-minus-operator-behavior-with-unsigned-operands
        let threshold = (UInt32.max - upperBound + 1) % upperBound

        // Uniformity guarantees that this loop will terminate.  In practice, it
        // should usually terminate quickly; on average (assuming all bounds are
        // equally likely), 82.25% of the time, we can expect it to require just
        // one iteration.  In the worst case, someone passes a bound of 2^31 + 1
        // (i.e., 2147483649), which invalidates almost 50% of the range.  In
        // practice, bounds are typically small and only a tiny amount of the range
        // is eliminated.
        while true {
            let r = advance()
            if r >= threshold {
                return r % upperBound
            }
        }
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
