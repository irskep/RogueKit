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

  func moved(relativeTo point: BLPoint) -> PrefabPort {
    return PrefabPort(point: point + self.point, direction: self.direction)
  }

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
  var metadata: PrefabMetadata

  init(sprite: REXPaintSprite, metadata: PrefabMetadata) {
    var ports = [PrefabPort]()
    for point in sprite.rect.moved(to: BLPoint.zero) {
      switch sprite.get(layer: 1, point: point).code {
      case CP437.ARROW_E: ports.append(PrefabPort(point: point, direction: BLPoint(x: 1, y: 0)))
      case CP437.ARROW_W: ports.append(PrefabPort(point: point, direction: BLPoint(x: -1, y: 0)))
      case CP437.ARROW_S: ports.append(PrefabPort(point: point, direction: BLPoint(x: 0, y: 1)))
      case CP437.ARROW_N: ports.append(PrefabPort(point: point, direction: BLPoint(x: 0, y: -1)))
      case CP437.DOT: ports.append(PrefabPort(point: point, direction: BLPoint.zero))
      default: continue
      }
    }
    self.sprite = sprite
    self.ports = ports
    self.metadata = metadata
  }

  static func ==(_ a: Prefab, _ b: Prefab) -> Bool {
    // Just trust that we didn't screw up the names of things
    return a.sprite.name == b.sprite.name
  }
}

class PrefabConnection {
  weak var a: PrefabInstance?
  weak var b: PrefabInstance?
  var port: PrefabPort
  init(a: PrefabInstance, b: PrefabInstance, port: PrefabPort) {
    self.a = a
    self.b = b
    self.port = port
  }

  func neighbor(of instance: PrefabInstance) -> PrefabInstance? { return a == instance ? b : a }
}

class PrefabInstance: Hashable, CustomDebugStringConvertible {
  let prefab: Prefab
  let point: BLPoint
  var connections = [PrefabConnection]()
  var cells: Array2D<GeneratorCell>
  var usedPorts = [PrefabPort]()
  var unusedPorts = [PrefabPort]()
  var mergedPorts = [PrefabPort]()

  init(prefab: Prefab, point: BLPoint) {
    self.point = point
    self.prefab = prefab
    self.cells = Array2D(size: prefab.sprite.rect.size, emptyValue: GeneratorCell.zero)
    for cellPoint in prefab.sprite.bounds {
      self.cells[cellPoint] = GeneratorCell(
        layer0Cell: prefab.sprite.get(layer: 0, point: cellPoint),
        layer1Cell: prefab.sprite.get(layer: 1, point: cellPoint),
        metadata: prefab.metadata)
      if let portDirection = self.cells[cellPoint].portDirection {
        let newPort = PrefabPort(point: point + cellPoint, direction: portDirection)
        unusedPorts.append(newPort)
      }
    }
  }

  convenience init(prefab: Prefab, point: BLPoint, usingPort usedPort: PrefabPort, toConnectTo counterpart: PrefabInstance) {
    // If port is at (1,1), and we're placing this to overlap (1, 10), then
    // we want to place the origin of the prefab instance at (0, 9).
    self.init(prefab: prefab, point: point - usedPort.point)
    self.connect(to: counterpart, with: usedPort.moved(relativeTo: self.point))
  }

  var rect: BLRect {
    return prefab.sprite.rect.moved(to: point)
  }

  func connect(to instance: PrefabInstance, with port: PrefabPort) {
    let oldPorts = unusedPorts
    self.unusedPorts = oldPorts.filter({ $0 != port })
//    if self.unusedPorts.count != oldPorts.count {
      usedPorts.append(port)
//    } else {
//      fatalError("Tried to use a port I don't have")
//    }
    self.connections.append(PrefabConnection(a: self, b: instance, port: port))
    let cellPoint = port.point - self.point
    self.cells[cellPoint].flags.remove(.portUnused)
    self.cells[cellPoint].flags.insert(.portUsed)
  }

  func disconnect(from instance: PrefabInstance) {
    for c in connections {
      if c.neighbor(of: self) == instance {
        self.usedPorts = usedPorts.filter({ $0 != c.port })
        self.unusedPorts.append(c.port)
        self.cells[c.port.point - self.point].flags.remove(.portUsed)
        self.cells[c.port.point - self.point].flags.insert(.portUnused)
      }
    }
    connections = connections.filter({ $0.neighbor(of: self) != instance })
  }

  func disconnectFromAll() {
    for c in connections {
      c.neighbor(of: self)?.disconnect(from: self)
    }
    self.connections = []
    self.unusedPorts = self.unusedPorts + self.usedPorts
    self.usedPorts = []
  }

  func removeCells(at points: [BLPoint]) {
    mergedPorts.append(contentsOf: unusedPorts.filter({ points.contains($0.point) }))
    unusedPorts = unusedPorts.filter({ !points.contains($0.point) })

    // usedPorts probably contains the cell we're using to connect to another
    // prefab instance, but it should be OK to remove it. We still track
    // the connection object for it.
    usedPorts = usedPorts.filter({ !points.contains($0.point) })
//    for p in points {
//      // Remember merged cells just in case
//      mergedCells[p] = self.generatorCell(at: p)
//      self.replaceGeneratorCell(at: p, with: GeneratorCell.zero)
//    }
  }

  var livePoints: [BLPoint] {
    return rect.filter({ self.cells[$0 - self.point].basicType != .empty })
  }

  var neighbors: [PrefabInstance] {
    return connections.flatMap({ $0.neighbor(of: self) })
  }

  func get(layer: Int, point: BLPoint) -> REXPaintCell {
    return prefab.sprite.get(layer: layer, point: point - self.point)
  }

  func generatorCell(at cellPoint: BLPoint) -> GeneratorCell {
    return self.cells[cellPoint - self.point]
  }

  func replaceGeneratorCell(at cellPoint: BLPoint, with cell: GeneratorCell) {
    self.cells[cellPoint - self.point] = cell
  }

  static func ==(_ a: PrefabInstance, _ b: PrefabInstance) -> Bool {
    return a.prefab == b.prefab && a.point == b.point
  }

  var hashValue: Int { return point.hashValue }

  var debugDescription: String {
    return "PrefabInstance(prefab=\(prefab), point=\(point))"
  }
}


struct GeneratorCell {
  var basicType: BasicType
  var flags: Set<GeneratorCellFlag>
  var portDirection: BLPoint?
  var poi: PrefabMetadata.POIDefinition?

  static var zero: GeneratorCell { return GeneratorCell() }

  init() {
    basicType = .empty
    flags = Set()
    portDirection = nil
    poi = nil
  }

  init(layer0Cell: REXPaintCell, layer1Cell: REXPaintCell, metadata: PrefabMetadata) {
    switch layer0Cell.code {
    case CP437.BLOCK: self.basicType = .wall
    case CP437.DOT: self.basicType = .floor
    case CP437.NULL, CP437.SPACE: self.basicType = .empty
    default: fatalError("Unknown cell type: \(layer0Cell.code)")
    }

    switch layer1Cell.code {
    case CP437.ARROW_E: self.flags = Set([.portUnused]); self.portDirection = BLPoint(x: 1, y: 0)
    case CP437.ARROW_W: self.flags = Set([.portUnused]); self.portDirection = BLPoint(x: -1, y: 0)
    case CP437.ARROW_S: self.flags = Set([.portUnused]); self.portDirection = BLPoint(x: 0, y: 1)
    case CP437.ARROW_N: self.flags = Set([.portUnused]); self.portDirection = BLPoint(x: 0, y: -1)
    case CP437.DOT: self.flags = Set([.portUnused]); self.portDirection = BLPoint.zero
    default:
      self.flags = Set()
      self.portDirection = nil
    }

    for poi in metadata.poiDefinitions {
      if poi.code == layer1Cell.code {
        self.poi = poi
        print("I got a POI!", poi)
        break
      }
    }
  }

  enum BasicType {
    case floor
    case wall
    case empty
  }

  enum GeneratorCellFlag: String {
    case portUsed
    case portUnused
    case createdToAddCycle
    case debugPoint
    case lateStageHallway
    case invisibleDoor

    // prefab origins
    case hasDoors
  }

  var isPassable: Bool {
    return basicType == .floor || flags.contains(.portUsed)
  }
}
