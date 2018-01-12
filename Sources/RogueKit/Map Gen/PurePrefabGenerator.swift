//
//  PurePrefabGenerator.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/10/18.
//

import Foundation
import BearLibTerminal


class PurePrefabGenerator {
  var cells: [[REXPaintCell]]
  let rng: RKRNGProtocol
  let resources: ResourceCollectionProtocol
  var prefabInstances = [PrefabInstance]()
  var openPorts = [(PrefabInstance, PrefabPort)]()

  var rect: BLRect { return BLRect(x: 0, y: 0, w: Int32(cells[0].count), h: Int32(cells.count)) }

  init(rng: RKRNGProtocol, resources: ResourceCollectionProtocol, size: BLSize) {
    self.rng = rng
    self.resources = resources
    self.cells = [[REXPaintCell]](
      repeating: [REXPaintCell](repeating: REXPaintCell.zero, count: Int(size.w)),
      count: Int(size.h))
  }

  private var _prefabsByDirection: [BLPoint: [Prefab]] = [
    BLPoint(x: -1, y: 0): [],
    BLPoint(x: 1, y: 0): [],
    BLPoint(x: 0, y: -1): [],
    BLPoint(x: 0, y: 1): [],
  ]

  func start() {
    let allPrefabs = Array(resources.prefabs.values)

    // Pick a random prefab without the 'hallway' marker. Place it randomly.
    let firstPrefab = rng.choice(allPrefabs.filter({ $0.sprite.metadata != "h" }))
    self.place(
      prefab: firstPrefab,
      at: rect.shrunk(by: firstPrefab.sprite.rect.size).randomPoint(rng))

    for p in allPrefabs {
      for port in p.ports {
        _prefabsByDirection[port.direction]?.append(p)
      }
    }
  }

  func iterate() {
    rng.shuffleInPlace(&openPorts)
    guard let portPair = openPorts.popLast() else { return }
    let (instance, port) = portPair
    let portDirectionInverse = port.direction * BLPoint(x: -1, y: -1)
    guard let candidates = _prefabsByDirection[portDirectionInverse] else {
      openPorts.append(portPair)
      return
    }
    let prefab = rng.choice(candidates)
    if let (newInstance, newPort) = self.tryPrefab(prefab, portPoint: port.point + port.direction, newPortDirection: portDirectionInverse) {
      self.register(prefabInstance: newInstance, omittingPort: newPort)
      self.usePort(instance: instance, port: port, counterpart: newInstance)
      self.usePort(instance: newInstance, port: newPort, counterpart: instance)
    }
  }

  func tryPrefab(_ prefab: Prefab, portPoint: BLPoint, newPortDirection: BLPoint) -> (PrefabInstance, PrefabPort)? {
    let validPorts = prefab.ports.filter({ $0.direction == newPortDirection })
    guard validPorts.count > 0 else {
      fatalError("Somehow decided to try a prefab without any ports in the right direction")
    }
    let port = rng.choice(validPorts)
    // If port is at (1,1), and we're placing this to overlap (1, 10), then
    // we want to place the origin of the prefab instance at (0, 9).
    let newInstanceOrigin = portPoint - port.point
    let newPort = PrefabPort(point: portPoint, direction: newPortDirection)
    let instance = PrefabInstance(prefab: prefab, point: newInstanceOrigin)
    guard rect.contains(rect: instance.rect) else { return nil }
    for point in instance.livePoints {
      if self.cells[Int(point.y)][Int(point.x)] != REXPaintCell.zero {
        return nil
      }
    }
    return (instance, newPort)
  }

  func usePort(instance: PrefabInstance, port: PrefabPort, counterpart: PrefabInstance) {
    instance.connections[port] = PrefabConnection(a: instance, b: counterpart)
    self.write(port.point, REXPaintCell(code: 219, foregroundColor: (0, 0, 0), backgroundColor: (0, 0, 0)))
  }

  func place(prefab: Prefab, at point: BLPoint) {
    self.register(prefabInstance: PrefabInstance(prefab: prefab, point: point))
  }

  func register(prefabInstance instance: PrefabInstance) {
    prefabInstances.append(instance)
    for port in instance.ports {
      openPorts.append((instance, port))
    }
    self.commit(instance: instance)
  }

  func register(prefabInstance instance: PrefabInstance, omittingPort omittedPort: PrefabPort) {
    prefabInstances.append(instance)
    for port in instance.ports(omitting: omittedPort) {
      openPorts.append((instance, port))
    }
    self.commit(instance: instance)
  }

  func commit(instance: PrefabInstance) {
    for point in instance.livePoints {
      self.write(point, instance.get(layer: 0, point: point))
    }
  }

  func write(_ point: BLPoint, _ cell: REXPaintCell) {
    cells[Int(point.y)][Int(point.x)] = cell
  }
}


extension PurePrefabGenerator: REXPaintDrawable {
  var layersCount: Int { return 1 }
  var width: Int32 { return Int32(cells[0].count) }
  var height: Int32 { return Int32(cells.count) }
  func get(layer: Int, x: Int, y: Int) -> REXPaintCell {
    return cells[y][x]
  }
}
