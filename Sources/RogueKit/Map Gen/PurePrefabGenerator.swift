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
    let delta = rng.get(upperBound: 2) == 0 ? port.direction : BLPoint.zero
    guard
      let newInstance = self.tryPrefab(
        prefab,
        portPoint: port.point + delta,
        newPortDirection: portDirectionInverse,
        counterpart: instance)
      else {
        openPorts.append(portPair)
        return
    }
    self.register(prefabInstance: newInstance)
    instance.connect(to: newInstance, with: port)
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

      var neighborPair: (PrefabInstance, PrefabPort)? = nil
      neighborPair = portMap[port.direction + port.point]
      guard let (neighborInstance, neighborPort) = neighborPair else { continue }

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
    // We might be smushing one prefab into another. We don't want two prefabs
    // covering the same cell, so give the existing one precedence over this one.
    var pointsToRemove = [BLPoint]()
    for point in instance.livePoints {
      let existingCell = self.cells[point]
      if existingCell.basicType == .empty { continue }
      if existingCell.flags.contains(.portUsed) { return nil }
      if existingCell.basicType == .wall && instance.generatorCell(at: point).basicType == .wall {
        pointsToRemove.append(point)
        continue
      }
      return nil
    }
    instance.removeCells(at: pointsToRemove)
    return instance
  }

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

  func commit(instance: PrefabInstance) {
    for point in instance.livePoints {
      self.cells[point] = instance.generatorCell(at: point)
    }
  }

  func recommitEverything() {
    self.cells = Array2D(size: rect.size, emptyValue: GeneratorCell.zero)
    for instance in prefabInstances {
      for point in instance.livePoints {
        let newCell = instance.generatorCell(at: point)
        let oldCell = self.cells[point]
        if oldCell.basicType == .empty {
          self.cells[point] = instance.generatorCell(at: point)
        } else {
          // Merge cells from two overlapping prefabs
          if newCell.flags.contains(.portUsed) {
            self.cells[point].flags.insert(.portUsed)
          } else if oldCell.flags.contains(.portUnused) && newCell.flags.contains(.portUnused) {
            self.cells[point].basicType = .floor
            self.cells[point].flags.insert(.portUsed)
            self.cells[point].flags.insert(.createdToAddCycle)
          }
        }
      }
    }
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
