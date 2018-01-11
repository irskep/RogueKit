//
//  Prefab.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/10/18.
//

import Foundation
import BearLibTerminal


struct PrefabPort: Hashable {
  var point: BLPoint
  var direction: BLPoint

  static func ==(_ a: PrefabPort, _ b: PrefabPort) -> Bool {
    return a.point == b.point && a.direction == b.direction
  }

  var hashValue: Int {
    return point.hashValue
  }
}


struct Prefab: Equatable {
  var sprite: REXPaintSprite
  var ports: [PrefabPort]

  init(sprite: REXPaintSprite) {
    var ports = [PrefabPort]()
    for point in sprite.rect.moved(to: BLPoint.zero) {
      switch sprite.get(layer: 1, point: point).code {
      case CP437.ARROW_E: ports.append(PrefabPort(point: point, direction: BLPoint(x: 1, y: 0)))
      case CP437.ARROW_W: ports.append(PrefabPort(point: point, direction: BLPoint(x: -1, y: 0)))
      case CP437.ARROW_S: ports.append(PrefabPort(point: point, direction: BLPoint(x: 0, y: 1)))
      case CP437.ARROW_N: ports.append(PrefabPort(point: point, direction: BLPoint(x: 0, y: -1)))
      default: continue
      }
    }
    self.sprite = sprite
    self.ports = ports
  }

  static func ==(_ a: Prefab, _ b: Prefab) -> Bool {
    // Just trust that we didn't screw up the names of things
    return a.sprite.name == b.sprite.name
  }
}

class PrefabConnection {
  weak var a: PrefabInstance?
  weak var b: PrefabInstance?
  init(a: PrefabInstance, b: PrefabInstance) {
    self.a = a
    self.b = b
  }

  func neighbor(of instance: PrefabInstance) -> PrefabInstance? { return a == instance ? b : a }
}

class PrefabInstance: Hashable, CustomDebugStringConvertible {
  let prefab: Prefab
  let point: BLPoint
  var connections = [PrefabPort: PrefabConnection]()
  // TODO: richer data structure than REXPaintCell for these?
  var replacements = [BLPoint: REXPaintCell]()

  init(prefab: Prefab, point: BLPoint) {
    self.point = point
    self.prefab = prefab
  }

  var rect: BLRect {
    return prefab.sprite.rect.moved(to: point)
  }

  lazy var ports: [PrefabPort] = {
    return prefab.ports.map({ PrefabPort(point: $0.point + self.point, direction: $0.direction) })
  }()

  func ports(omitting: PrefabPort) -> [PrefabPort] {
    return prefab.ports.filter({ $0 != omitting }).map({ PrefabPort(point: $0.point + self.point, direction: $0.direction) })
  }

  lazy var livePoints: [BLPoint] = {
    var points = [BLPoint]()
    for y in 0..<Int(prefab.sprite.rect.h) {
      for x in 0..<Int(prefab.sprite.rect.w) {
        let point = BLPoint(x: Int32(x), y: Int32(y))
        let cell = prefab.sprite.get(layer: 0, point: point)
        if cell.code == 0 || cell.code == 32 { continue }
        points.append(point + self.point)
      }
    }
    return points
  }()

  var neighbors: [PrefabInstance] {
    return connections.values.flatMap({ $0.neighbor(of: self) })
  }

  func get(layer: Int, point: BLPoint) -> REXPaintCell {
    return prefab.sprite.get(layer: layer, point: point - self.point)
  }

  static func ==(_ a: PrefabInstance, _ b: PrefabInstance) -> Bool {
    return a.prefab == b.prefab && a.point == b.point
  }

  var hashValue: Int { return point.hashValue }

  var debugDescription: String {
    return "PrefabInstance(prefab=\(prefab), point=\(point))"
  }
}
