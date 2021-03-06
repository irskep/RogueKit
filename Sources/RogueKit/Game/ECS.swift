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


protocol ECSRemovable {
  func remove(entity: Entity)
}


protocol ECSComponent: class, Comparable {
  var entity: Int? { get set }
}
extension ECSComponent {
  static func <(lhs: Self, rhs: Self) -> Bool {
    guard let a = lhs.entity, let b = rhs.entity else { return false }
    return a < b
  }

  static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.entity == rhs.entity
  }
}


class ECSSystem<T: ECSComponent & Codable>: ECSRemovable {
  private var e2c = [Entity: T]()

  // It would be more efficient to use a linked list here, but for now we just
  // keep 'em sorted by entity ID for long-time removal.
  var _all = [T]()
  var all: [T] { return _all }

  enum CodingKeys: String, CodingKey {
    case e2c
    case all
  }

  required init() { }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    e2c = try values.decode([Entity: T].self, forKey: .e2c)
    _all = e2c.values.sorted(by: { ($0.entity ?? -1) < ($1.entity ?? -1) })
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(e2c, forKey: .e2c)
  }

  subscript(index: Int) -> T? { return self.get(index) }

  func get(_ entity: Int) -> T? { return e2c[entity] }

  func add(entity: Entity, component: T) {
    guard e2c[entity] == nil else { fatalError("Trying to double-register a \(T.self)") }
    e2c[entity] = component
    component.entity = entity
    _all.append(component)
    _all.sort(by: {
      guard let a = $0.entity, let b = $1.entity else { return false }
      return a < b
    })
  }

  @discardableResult
  func add(component: T) -> T {
    guard let entity = component.entity else {
      fatalError("Can't add a component this way w/o an entity on it")
    }
    self.add(entity: entity, component: component)
    return component
  }

  func remove(entity: Entity) {
    guard let c = e2c[entity] else { return }
    e2c[entity] = nil
    if let pos = binarySearch(all, key: c, range: 0..<all.count) {
      _all.remove(at: pos)
    }
  }
}
