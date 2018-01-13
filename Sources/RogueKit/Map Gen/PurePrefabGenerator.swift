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
  var zeroPorts = [(PrefabInstance, PrefabPort)]()

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
    guard
      let (newInstance, newPort) = self.tryPrefab(
        prefab,
        portPoint: port.point + port.direction,
        newPortDirection: portDirectionInverse)
      else {
        openPorts.append(portPair)
        return
    }
    self.register(prefabInstance: newInstance, omittingPort: newPort)
    self.usePort(instance: instance, port: port, counterpart: newInstance)
    self.usePort(instance: newInstance, port: newPort, counterpart: instance)
  }

  func drawOpenPorts(in terminal: BLTerminalInterface) {
    for (_, port) in openPorts {
      guard rect.contains(point: port.point + port.direction) else { continue }
      terminal.foregroundColor = terminal.getColor(name: "black")
      terminal.backgroundColor = terminal.getColor(name: "white")
      terminal.put(point: port.point, code: 120)
      terminal.backgroundColor = terminal.getColor(name: "black")
    }
  }

  func connectAdjacentPorts() {
    var portMap = Array2D<(PrefabInstance, PrefabPort)?>(size: rect.size, emptyValue: nil)
    var newlyUsedPorts = [(PrefabInstance, PrefabPort)]()

    for (instance, port) in zeroPorts {
      guard rect.contains(point: port.point + port.direction) else { continue }
      portMap[port.point] = (instance, port)
    }

    rng.shuffleInPlace(&openPorts)
    var numCycles = 0
    for (instance, port) in openPorts {
      guard numCycles < 10 else { break }
      guard rect.contains(point: port.point + port.direction) else { continue }
      portMap[port.point] = (instance, port)

      if let (neighborInstance, neighborPort) = portMap[port.direction + port.point] {
        print("Added a cycle by joining adjacent ports")
        numCycles += 1
        portMap[port.direction + port.point] = nil
        portMap[port.point] = nil
        newlyUsedPorts.append((instance, port))
        newlyUsedPorts.append((neighborInstance, neighborPort))
        usePort(instance: instance, port: port, counterpart: neighborInstance)
        usePort(instance: neighborInstance, port: neighborPort, counterpart: instance)
//        self.write(port.point, REXPaintCell(code: 219, foregroundColor: (255, 0, 255), backgroundColor: (255, 0, 255)))
//        self.write(port.direction + port.point, REXPaintCell(code: 219, foregroundColor: (255, 0, 255), backgroundColor: (255, 0, 255)))
      }
    }
  } 

  func tryPrefab(_ prefab: Prefab, portPoint: BLPoint, newPortDirection: BLPoint) -> (PrefabInstance, PrefabPort)? {
    let validPorts = prefab.ports.enumerated().filter({ (i: Int, p: PrefabPort) -> Bool in p.direction == newPortDirection })
    guard validPorts.count > 0 else {
      fatalError("Somehow decided to try a prefab without any ports in the right direction")
    }
    let indexedPort = rng.choice(validPorts)
    // If port is at (1,1), and we're placing this to overlap (1, 10), then
    // we want to place the origin of the prefab instance at (0, 9).
    let newInstanceOrigin = portPoint - indexedPort.1.point
    let instance = PrefabInstance(prefab: prefab, point: newInstanceOrigin)
    let newPort = instance.ports[indexedPort.0]
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
    openPorts = openPorts.filter({ (duple) -> Bool in duple.0 != instance || duple.1 != port })
    self.write(port.point, REXPaintCell(code: 219, foregroundColor: (0, 0, 0), backgroundColor: (0, 0, 0)))
  }

  func place(prefab: Prefab, at point: BLPoint) {
    self.register(prefabInstance: PrefabInstance(prefab: prefab, point: point))
  }

  func register(prefabInstance instance: PrefabInstance, omittingPort omittedPort: PrefabPort? = nil) {
    prefabInstances.append(instance)
    let ports: [PrefabPort]
    if let omittedPort = omittedPort {
      ports = instance.ports(omitting: omittedPort)
    } else {
      ports = instance.ports
    }
    // TODO: instead of ports w/ and w/o direction, use "active" and "passive"
    // ports that all have direction
    for port in ports {
      if port.direction == BLPoint.zero {
        zeroPorts.append((instance, port))
      } else {
        openPorts.append((instance, port))
      }
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
