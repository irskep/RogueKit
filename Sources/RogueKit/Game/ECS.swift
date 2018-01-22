//
//  ECS.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/21/18.
//


// https://github.com/raywenderlich/swift-algorithm-club/tree/master/Binary%20Search
private func binarySearch<T: Comparable>(_ a: [T], key: T, range: Range<Int>) -> Int? {
  if range.lowerBound >= range.upperBound {
    // If we get here, then the search key is not present in the array.
    return nil

  } else {
    // Calculate where to split the array.
    let midIndex = range.lowerBound + (range.upperBound - range.lowerBound) / 2

    // Is the search key in the left half?
    if a[midIndex] > key {
      return binarySearch(a, key: key, range: range.lowerBound ..< midIndex)

      // Is the search key in the right half?
    } else if a[midIndex] < key {
      return binarySearch(a, key: key, range: midIndex + 1 ..< range.upperBound)

      // If we get here, then we've found the search key!
    } else {
      return midIndex
    }
  }
}


class ECSComponent {
  var entity: Int?
  init(entity: Int?) { self.entity = entity }
}
extension ECSComponent: Comparable {
  static func <(lhs: ECSComponent, rhs: ECSComponent) -> Bool {
    guard let a = lhs.entity, let b = rhs.entity else { return false }
    return a < b
  }

  static func ==(lhs: ECSComponent, rhs: ECSComponent) -> Bool {
    return lhs.entity == rhs.entity
  }
}


class ECSSystem<T: ECSComponent> {
  private var e2c = [Int: T]()

  // It would be more efficient to use a linked list here, but for now we just
  // keep 'em sorted by entity ID for logn-time removal.
  var all = [T]()

  subscript(index: Int) -> T? { return self.get(index) }

  func get(_ index: Int) -> T? { return e2c[index] }

  func add(entity: Int, component: T) {
    guard e2c[entity] == nil else { fatalError("Trying to double-register a \(T.self)") }
    e2c[entity] = component
    all.append(component)
    all.sort(by: {
      guard let a = $0.entity, let b = $1.entity else { return false }
      return a < b
    })
  }

  func remove(entity: Int) {
    guard let c = e2c[entity] else { return }
    e2c[entity] = nil
    if let pos = binarySearch(all, key: c, range: 0..<all.count) {
      all.remove(at: pos)
    }
  }
}
