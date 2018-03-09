//
//  PurePrefabGenerator.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/10/18.
//

import Foundation
import BearLibTerminal


extension Prefab: WeightedChoosable {
  var id: String { return metadata.id }
  var weight: Double { return metadata.weight }
}


class PurePrefabGenerator {
  var cells: Array2D<GeneratorCell>
  let rng: RKRNGProtocol
  let resources: ResourceCollectionProtocol
  let mapDefinition: MapDefinition
  var prefabInstances = [PrefabInstance]()
  var openPorts = [(PrefabInstance, PrefabPort)]()
  var zeroPorts = [(PrefabInstance, PrefabPort)]()
  var pointsBlacklistedForHallways = Set<BLPoint>()
  var debugDistanceField: DistanceField?

  // WARNING: DOES NOT REDUCE WHEN REMOVING HALLWAYS
  var instanceCounts = [String: Int]()

  var rect: BLRect { return BLRect(x: 0, y: 0, w: cells.size.w, h: cells.size.h) }

  lazy var prefabsByTag: [String: [Prefab]] = {
    var result = [String: [Prefab]]()
    for p in resources.prefabs.values {
      for t in p.metadata.tags {
        if result[t] == nil { result[t] = [] }
        result[t]?.append(p)
      }
    }
    return result
  }()

  init(rng: RKRNGProtocol, resources: ResourceCollectionProtocol, size: BLSize, mapDefinition: MapDefinition) {
    self.rng = rng
    self.resources = resources
    self.cells = Array2D(size: size, emptyValue: GeneratorCell.zero)
    self.mapDefinition = mapDefinition

    for p in Array(resources.prefabs.values) {
      if !p.metadata.matches(mapDefinition.tagWhitelist) {
        print("Excluding prefab \(p.metadata.id)")
        continue
      }
      print("Including prefab \(p.metadata.id)")
      for port in p.ports {
        _prefabsByDirection[port.direction]?.append(p)
      }
    }
  }

  private var _prefabsByDirection: [BLPoint: [Prefab]] = [
    BLPoint(x: -1, y: 0): [],
    BLPoint(x: 1, y: 0): [],
    BLPoint(x: 0, y: -1): [],
    BLPoint(x: 0, y: 1): [],
  ]

  func points(where predicate: (GeneratorCell) -> Bool) -> [BLPoint] {
    return Array(rect.filter({ predicate(self.cells[$0]) }))
  }

  func placePrefab(tag: String) {
    let p = rng.choice(prefabsByTag[tag]!)
    self.register(
      prefabInstance: PrefabInstance(
        prefab: p,
        point: rect.shrunk(by: p.sprite.rect.size).randomPoint(rng)))
  }

  func growPrefabs() {
    rng.shuffleInPlace(&openPorts)
    guard let portPair = openPorts.popLast() else { return }
    let (instance, port) = portPair
    let portDirectionInverse = port.direction * BLPoint(x: -1, y: -1)
    let candidates = _prefabsByDirection[portDirectionInverse]?
      .filter({
        if $0.metadata.maxInstances > 0 && (instanceCounts[$0.metadata.id] ?? 0) >= $0.metadata.maxInstances {
          return false
        }
        return (
          $0.metadata.matches(instance.prefab.metadata.neighborTags) &&
            instance.prefab.metadata.matches($0.metadata.neighborTags))
      }) ?? []
    guard instance.availablePorts > 0, !candidates.isEmpty else {
      if candidates.isEmpty {
        print("No neighbor candidates for \(instance.prefab.id)")
      }
//      openPorts.append(portPair)
      return
    }
    let prefab = WeightedChoice.choose(rng: rng, items: candidates)
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
    self.usePort(instance: instance, port: port, counterpart: newInstance)
    instanceCounts[prefab.metadata.id] = (instanceCounts[prefab.metadata.id] ?? 0) + 1
  }

  func connectAdjacentPorts(maxNewCycles: Int = 10) {
    var portMap = Array2D<(PrefabInstance, PrefabPort)?>(size: rect.size, emptyValue: nil)
    var newlyUsedPorts = [(PrefabInstance, PrefabPort)]()

    for (instance, port) in zeroPorts {
      guard rect.contains(point: port.point + port.direction) else { continue }
      portMap[port.point] = (instance, port)
    }

    rng.shuffleInPlace(&openPorts)
    var numCycles = 0
    for (instance, port) in openPorts {
      guard numCycles < maxNewCycles else { break }
      guard rect.contains(point: port.point + port.direction) else { continue }
      portMap[port.point] = (instance, port)

      var neighborPair: (PrefabInstance, PrefabPort)? = nil
      neighborPair = portMap[port.direction + port.point]
      guard let (neighborInstance, neighborPort) = neighborPair else { continue }
      guard neighborInstance.unusedPorts.contains(neighborPort) && instance.unusedPorts.contains(port) else { continue }
      guard neighborInstance.availablePorts > 0, instance.availablePorts > 0 else { continue }

      numCycles += 1
      portMap[port.direction + port.point] = nil
      portMap[port.point] = nil
      newlyUsedPorts.append((instance, port))
      newlyUsedPorts.append((neighborInstance, neighborPort))
      self.usePort(instance: instance, port: port, counterpart: neighborInstance)
      self.usePort(instance: neighborInstance, port: neighborPort, counterpart: instance)

      var cell1 = instance.generatorCell(at: port.point)
      cell1.flags.insert(.createdToAddCycle)
      instance.replaceGeneratorCell(at: port.point, with: cell1)

      var cell2 = neighborInstance.generatorCell(at: neighborPort.point)
      cell2.flags.insert(.createdToAddCycle)
      neighborInstance.replaceGeneratorCell(at: neighborPort.point, with: cell2)
    }

    openPorts = openPorts.filter({
      return !self.cells[$0.1.point].flags.contains(.portUsed)
    })
  }

  func removeDeadEnds(mustTerminateWithTagOtherThan hallwayTag: String) {
    var deadEnds = [PrefabInstance]()
    var notDeadEnds = [PrefabInstance]()
    let update: () -> () = {
      deadEnds = self.prefabInstances.filter({
        return $0.connections.count == 1 && $0.prefab.metadata.tags.contains(hallwayTag)
      })
      notDeadEnds = self.prefabInstances.filter({
        return $0.connections.count != 1 || !$0.prefab.metadata.tags.contains(hallwayTag)
      })
      self.prefabInstances = notDeadEnds
    }
    update()
    while deadEnds.count > 0 {
      for instance in deadEnds {
        instance.disconnectFromAll()
        for point in instance.livePoints {
          if self.cells[point].flags.contains(.portUsed) {
            self.cells[point].flags.remove(.portUsed)
            self.cells[point].flags.insert(.portUnused)
          }
        }
      }
      update()
    }
    openPorts = []
    zeroPorts = []
    for i in prefabInstances {
      for port in i.unusedPorts {
        if port.direction == BLPoint.zero {
          zeroPorts.append((i, port))
        } else {
          openPorts.append((i, port))
        }
      }
    }
    recommitEverything()
  }

  func addHallwayToPortFurthestFromACycle(numIterations: Int = 5) {
    var allUnusedPorts = [PrefabPort]()
    for i in prefabInstances {
      allUnusedPorts.append(contentsOf: i.unusedPorts.filter({ $0.direction != BLPoint.zero }))
    }

    var cyclePoints = self.rect.filter({ self.cells[$0].flags.contains(.createdToAddCycle) })
    if cyclePoints.isEmpty {  // in case there happened to be no cycles
      var p = rng.choice(prefabInstances).usedPorts.first?.point
      if let p = p {
        cyclePoints = [p]
      } else {
        var i = 0
        while i < 100 && p == nil {
          p = rng.choice(prefabInstances).usedPorts.first?.point
          i += 1
          if let p = p {
            cyclePoints = [p]
            break
          }
        }
        print("Couldn't add a cycle-creating hallway because there are no hallways")
        return
      }
    }

    let field = DistanceField(size: self.rect.size)
    field.populate(seeds: cyclePoints, isPassable: {
      let cell = self.cells[$0]
      if cell.flags.contains(.lateStageHallway) { return false }
      if cell.isPassable { return true }
      return cell.flags.contains(.portUnused) && cell.portDirection != BLPoint.zero
    })

//    debugDistanceField = field

    var numIterationsLeft = numIterations
    var numIterationsUsed = 0
    while numIterationsLeft > 0 && numIterationsUsed < numIterations * 6 {
      numIterationsUsed += 1
      if let hallwayStart = field.findMaximum(where: {
        if !self.cells[$0].flags.contains(.portUnused) { return false }
        if self.pointsBlacklistedForHallways.contains($0) { return false }
        for neighbor in $0.getNeighbors(bounds: self.rect, diagonals: false) {
          if self.cells[neighbor].basicType == .empty { return true }
        }
        return false
      }) {
        pointsBlacklistedForHallways.insert(hallwayStart)
        if self.addHallwayToNearestUnusedPort(origin: hallwayStart, minExistingDistance: 40) {
          numIterationsLeft -= 1
        }
      }
    }
  }

  func addHallwayToNearestUnusedPort(origin: BLPoint, minExistingDistance: Int = 40) -> Bool {
    var allUnusedPorts = [PrefabPort]()
    for i in prefabInstances {
      guard i.availablePorts > 0 else { continue }
      allUnusedPorts.append(contentsOf: i.unusedPorts.filter({ $0.direction != BLPoint.zero && $0.point != origin }))
    }

    let originProximityField = DistanceField(size: self.rect.size)
    originProximityField.populate(seeds: [origin], isPassable: {
      return self.cells[$0].isPassable || self.cells[$0].flags.contains(.portUnused)
    })

    let field = DistanceField(size: self.rect.size)
    field.populate(
      seeds: Array(Set<BLPoint>(allUnusedPorts.map({ $0.point })))
        .filter({ originProximityField.cells[$0] >= minExistingDistance }),
      isPassable: {
        self.cells[$0].basicType == .empty ||
          self.cells[$0].basicType == .floor
    })

    field.cells[origin] = field.maxVal + 1

//    debugDistanceField = field

    var lastPoint = origin
    var maybeNextPoint: BLPoint? = nil
    let advance: () -> Void = {
      maybeNextPoint = lastPoint.getNeighbors(bounds: self.rect, diagonals: false)
        .filter({
          if field.cells[$0] >= field.cells[lastPoint] { return false }
          return self.cells[$0].basicType == .empty || self.cells[$0].flags.contains(.portUnused)
        })
        .first
    }
    advance()

    var hallPoints = [BLPoint]()
    var endPoint: BLPoint? = nil
    while let nextPoint = maybeNextPoint {
      lastPoint = nextPoint
      if self.cells[lastPoint].flags.contains(.portUnused) || self.cells[lastPoint].basicType == .floor {
        endPoint = lastPoint
        break
      }
      hallPoints.append(lastPoint)
      advance()
      if hallPoints.count >= 25 { return false } // long hallways are boring
    }

    if let endPoint = endPoint {
      // TODO: make prefab out of this instead? remember the hallways so we can add more rooms?
      for p in [origin, endPoint] {
        self.cells[p].flags.remove(.portUnused)
        self.cells[p].flags.insert(.portUsed)
        self.cells[p].flags.insert(.createdToAddCycle)
        self.cells[p].flags.insert(.debugPoint)
        self.cells[p].flags.insert(.lateStageHallway)
        self.cells[p].poi = PrefabMetadata.POIDefinition(
          code: 0, kind: .mob, tags: ["hall"], isRequired: false)
      }

      var lastHallPoint = hallPoints.first
      for hallPoint in hallPoints {
        self.cells[hallPoint].basicType = .floor
        self.cells[hallPoint].flags.insert(.createdToAddCycle)
        self.cells[hallPoint].flags.insert(.debugPoint)
        self.cells[hallPoint].flags.insert(.lateStageHallway)
        if let lhp = lastHallPoint {
          let delta = hallPoint - lhp
          self.cells[hallPoint].portDirection = rng.choice([
            delta.rotatedCounterClockwise, delta.rotatedClockwise])
        }
        lastHallPoint = hallPoint
      }
      return true
    } else {
      return false
    }
  }

  func addWallsNextToBareFloor() {  // Incidentally removes orphan doors
    var newWallPoints = [BLPoint]()
    for point in rect {
      if self.cells[point].basicType == .empty {
        for neighbor in point.getNeighbors(bounds: rect, diagonals: true) {
          if self.cells[neighbor].isPassable {
            newWallPoints.append(point)
            break
          }
        }
      } else if self.cells[point].flags.contains(.portUsed) {
        let numFloorNeighbors = point.getNeighbors(bounds: rect, diagonals: false)
          .filter({ self.cells[$0].isPassable })
          .count
        if numFloorNeighbors != 2 {
          self.cells[point].flags.remove(.portUsed)
          self.cells[point].flags.insert(.portUnused)
        }
      }
    }

    for point in newWallPoints {
      self.cells[point].basicType = .wall
    }
  }

  func removeDoubleDoors() {
    for point in rect {
      guard self.cells[point].flags.contains(.portUsed) else { continue }
      inner: for neighbor in point.getNeighbors(bounds: rect, diagonals: false) {
        if self.cells[neighbor].flags.contains(.portUsed) && !self.cells[neighbor].flags.contains(.invisibleDoor) {
          self.cells[point].flags.insert(.invisibleDoor)
          break inner
        }
      }
    }
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
      if existingCell.flags.contains(.portUsed) { return nil }  // already taken by another PAIR of prefabs
      if (existingCell.basicType == .wall && instance.generatorCell(at: point).basicType == .wall) ||
        (existingCell.basicType == .floor && instance.generatorCell(at: point).basicType == .floor)
        {
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

  func usePort(instance: PrefabInstance, port: PrefabPort, counterpart: PrefabInstance) {
    instance.connect(to: counterpart, with: port)
    self.cells[port.point].flags.remove(.portUnused)
    self.cells[port.point].flags.insert(.portUsed)
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
          // TODO: add this back, but blacklist prefabs with no available ports
          if newCell.flags.contains(.portUsed) {
            self.cells[point].flags.insert(.portUsed)
          } else if oldCell.flags.contains(.portUnused) &&
            newCell.flags.contains(.portUnused) &&
            instance.availablePorts > 0 && false
          {
            self.cells[point].basicType = .floor
            self.cells[point].flags.insert(.portUsed)
            self.cells[point].flags.insert(.createdToAddCycle)
          }
        }
        if instance.prefab.metadata.hasDoors {
          self.cells[point].flags.insert(.hasDoors)
        }
      }
    }
  }

  func drawOpenPorts(in terminal: BLTerminalInterface) {
    for (_, port) in openPorts {
      guard rect.contains(point: port.point + port.direction) else { continue }
      terminal.foregroundColor = terminal.getColor(name: "red")
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

    if cell.flags.contains(.debugPoint) {
      return REXPaintCell(code: 88, foregroundColor: (255, 0, 255), backgroundColor: (0, 0, 0))
    }

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

extension PurePrefabGenerator: GeneratorProtocol {
  enum Command: String {
    case placePrefab
    case growPrefabs
    case connectAdjacentPorts
    case removeDeadEnds
    case addHallwaysToRemoteAreas
    case addWallsNextToBareFloor
    case removeDoubleDoors
  }

  func runCommand(cmd: String, args: [String]) {
    guard let command = Command(rawValue: cmd) else { fatalError("Unknown command: \(cmd)") }
    let intArgs: [Int] = args.map({
      guard let int = Int($0) else { return -1 }
      return int
    })
    switch command {
    case .placePrefab:
      self.placePrefab(tag: args[0])
    case .growPrefabs where intArgs.count >= 1:
      for _ in 0..<(intArgs[0]) { self.growPrefabs() }
    case .connectAdjacentPorts where intArgs.count >= 1:
      self.connectAdjacentPorts(maxNewCycles: intArgs[0])
    case .removeDeadEnds:
      self.removeDeadEnds(mustTerminateWithTagOtherThan: args[0])
    case .addHallwaysToRemoteAreas where intArgs.count >= 2:
      for _ in 0..<intArgs[0] {
        self.addHallwayToPortFurthestFromACycle(numIterations: intArgs[1])
      }
    case .addWallsNextToBareFloor:
      self.addWallsNextToBareFloor()
    case .removeDoubleDoors:
      self.removeDoubleDoors()
    default:
      fatalError("Not enough arguments to \(cmd)")
    }
  }
}
