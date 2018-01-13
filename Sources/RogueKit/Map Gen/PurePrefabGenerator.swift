//
//  PurePrefabGenerator.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/10/18.
//

import Foundation
import BearLibTerminal


class PurePrefabGenerator {
  var cells: Array2D<GeneratorCell>
  let rng: RKRNGProtocol
  let resources: ResourceCollectionProtocol
  var prefabInstances = [PrefabInstance]()
  var openPorts = [(PrefabInstance, PrefabPort)]()
  var zeroPorts = [(PrefabInstance, PrefabPort)]()

  var rect: BLRect { return BLRect(x: 0, y: 0, w: cells.size.w, h: cells.size.h) }

  init(rng: RKRNGProtocol, resources: ResourceCollectionProtocol, size: BLSize) {
    self.rng = rng
    self.resources = resources
    self.cells = Array2D(size: size, emptyValue: GeneratorCell.zero)
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
    self.register(
      prefabInstance: PrefabInstance(
        prefab: firstPrefab,
        point: rect.shrunk(by: firstPrefab.sprite.rect.size).randomPoint(rng)))

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
      let newInstance = self.tryPrefab(
        prefab,
        portPoint: port.point + port.direction,
        newPortDirection: portDirectionInverse,
        counterpart: instance)
      else {
        openPorts.append(portPair)
        return
    }
    self.register(prefabInstance: newInstance)
    instance.connect(to: newInstance, with: port)
//    self.usePort(instance: instance, port: port, counterpart: newInstance)
//    self.usePort(instance: newInstance, port: newPort, counterpart: instance)
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
        instance.connect(to: neighborInstance, with: port)
        neighborInstance.connect(to: instance, with: neighborPort)

        var cell1 = instance.generatorCell(at: port.point)
        cell1.flags.insert(.createdToAddCycle)
        instance.replaceGeneratorCell(at: port.point, with: cell1)

        var cell2 = neighborInstance.generatorCell(at: neighborPort.point)
        cell2.flags.insert(.createdToAddCycle)
        neighborInstance.replaceGeneratorCell(at: neighborPort.point, with: cell2)
//        usePort(instance: instance, port: port, counterpart: neighborInstance)
//        usePort(instance: neighborInstance, port: neighborPort, counterpart: instance)
//        self.write(port.point, REXPaintCell(code: 219, foregroundColor: (255, 0, 255), backgroundColor: (255, 0, 255)))
//        self.write(port.direction + port.point, REXPaintCell(code: 219, foregroundColor: (255, 0, 255), backgroundColor: (255, 0, 255)))
      }
    }
  }

  func removeDeadEnds() {
    var deadEnds = [PrefabInstance]()
    var notDeadEnds = [PrefabInstance]()
    let update: () -> () = {
      deadEnds = self.prefabInstances.filter({
        return $0.connections.count == 1 && $0.prefab.sprite.metadata.contains("h")
      })
      notDeadEnds = self.prefabInstances.filter({
        return $0.connections.count != 1 || !$0.prefab.sprite.metadata.contains("h")
      })
      self.prefabInstances = notDeadEnds
    }
    update()
    while deadEnds.count > 0 {
      for instance in deadEnds {
        instance.disconnectFromAll()
      }
      update()
    }
    openPorts = []
    for i in prefabInstances {
      openPorts.append(contentsOf: i.unusedPorts.map({ (i, $0) }))
    }
    recommitEverything()
  }

  func tryPrefab(_ prefab: Prefab, portPoint: BLPoint, newPortDirection: BLPoint, counterpart: PrefabInstance) -> PrefabInstance? {
    let validPorts = prefab.ports.filter({ (p: PrefabPort) -> Bool in p.direction == newPortDirection })
    guard validPorts.count > 0 else {
      fatalError("Somehow decided to try a prefab without any ports in the right direction")
    }
    let port = rng.choice(validPorts)
    let instance = PrefabInstance(prefab: prefab, point: portPoint, usingPort: port, toConnectTo: counterpart)
    guard rect.contains(rect: instance.rect) else { return nil }
    for point in instance.livePoints {
      if self.cells[point].basicType != .empty {
        return nil
      }
    }
    return instance
  }

//  func usePort(instance: PrefabInstance, port: PrefabPort, counterpart: PrefabInstance) {
//    instance.connect(to: counterpart, with: port)
//    openPorts = openPorts.filter({ (duple) -> Bool in duple.0 != instance || duple.1 != port })
//    self.write(port.point, REXPaintCell(code: 219, foregroundColor: (0, 0, 0), backgroundColor: (0, 0, 0)))
//  }

  func register(prefabInstance instance: PrefabInstance) {
    prefabInstances.append(instance)
    // TODO: instead of ports w/ and w/o direction, use "active" and "passive"
    // ports that all have direction
    for port in instance.unusedPorts {
      if port.direction == BLPoint.zero {
        zeroPorts.append((instance, port))
      } else {
        openPorts.append((instance, port))
      }
    }
    self.commit(instance: instance)
  }

//  func commit(instance: PrefabInstance) {
//    for point in instance.livePoints {
//      self.write(point, instance.get(layer: 0, point: point))
//    }
//  }
//
//  func write(_ point: BLPoint, _ cell: REXPaintCell) {
//    cells[Int(point.y)][Int(point.x)] = cell
//  }

  func commit(instance: PrefabInstance) {
    for point in instance.livePoints {
      self.cells[point] = instance.generatorCell(at: point)
    }
  }

  func recommitEverything() {
    self.cells = Array2D(size: rect.size, emptyValue: GeneratorCell.zero)
    for instance in prefabInstances {
      for point in instance.livePoints {
        self.cells[point] = instance.generatorCell(at: point)
      }
    }
  }
}


extension PurePrefabGenerator: REXPaintDrawable {
  var layersCount: Int { return 1 }
  var width: Int32 { return cells.size.w }
  var height: Int32 { return cells.size.h }
  func get(layer: Int, x: Int, y: Int) -> REXPaintCell {
    let cell = self.cells[BLPoint(x: Int32(x), y: Int32(y))]

    if cell.flags.contains(.portUsed) {
      if cell.flags.contains(.createdToAddCycle) {
        return REXPaintCell(code: CP437.PLUS, foregroundColor: (0, 255, 0), backgroundColor: (0, 0, 0))
      } else {
        return REXPaintCell(code: CP437.PLUS, foregroundColor: (128, 64, 0), backgroundColor: (0, 0, 0))
      }
    }

    switch cell.basicType {
    case .wall: return REXPaintCell(code: CP437.BLOCK, foregroundColor: (255, 255, 255), backgroundColor: (0, 0, 0))
    case .floor: return REXPaintCell(code: CP437.DOT, foregroundColor: (55, 55, 55), backgroundColor: (0, 0, 0))
    case .empty: return REXPaintCell.zero
    }
  }
}
