//
//  LevelMap.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/20/18.
//

import Foundation
import BearLibTerminal

typealias FeatureID = Int
typealias TerrainID = Int

struct Terrain: Codable {
  let id: Int
  let name: String
  let char: Int
  let color: String
  let canSeeThrough: Bool
  let walkable: Bool
}


struct Feature: Codable {
  let id: Int
  let name: String
  let char: Int
  let color: String
  let canSeeThrough: Bool
  let walkable: Bool
  let pathable: Bool
}

struct Interaction: Codable {
  let name: String
  let blocksMovement: Bool
  let script: String
}

struct MapCell: Codable {
  var terrain: Int
  var feature: Int
  var prefabId: String?

  static let zero = { return MapCell(terrain: 0, feature: 0, prefabId:  nil) }()
}

extension MapCell {
  init(generatorCell: GeneratorCell) {
    self.prefabId = generatorCell.prefabId
    if generatorCell.flags.contains(.portUsed) &&
       !generatorCell.flags.contains(.invisibleDoor) &&
       generatorCell.flags.contains(.hasDoors) {
      self.terrain = 1
      self.feature = 2
      return
    }
    if generatorCell.flags.contains(.staticDoor) {
      self.terrain = 1
      self.feature = 2
      return
    }
    self.feature = 0
    switch generatorCell.basicType {
    case .floor,
         _ where generatorCell.flags.contains(.portUsed):
      self.terrain = 1
    case .empty:
      self.terrain = 0
    case .wall:
      self.terrain = 2
    }
  }
}


struct PointOfInterest: Codable {
  let kind: String
  var point: BLPoint
}


class LevelMap: Codable {
  let terrains: [Int: Terrain]
  let features: [Int: Feature]
  let featureIdsByName: [String: Int]
  let interactions: [Int: Interaction]
  let definition: MapDefinition
  var cells: CodableArray2D<MapCell>
  var palette: PaletteStore

  private func _isEmptyFloor(point: BLPoint) -> Bool {
    return cells[point]?.terrain == 1 && cells[point]?.feature == 0
  }

  lazy var floors: [BLPoint] = {
    return Array(BLRect(size: size).filter({ self._isEmptyFloor(point: $0) }))
  }()

  lazy var floorsWithMargins: [BLPoint] = {
    var points = [BLPoint]()
    for point in BLRect(size: size) {
      if !_isEmptyFloor(point: point) { continue }
      let emptyNeighbors = point
        .getNeighbors(bounds: BLRect(size: cells.size), diagonals: false)
        .filter({ self._isEmptyFloor(point: $0) })
      if emptyNeighbors.count == 4 {
        points.append(point)
      }
    }
    return points
  }()

  var mapMemory = Set<BLPoint>()

  var pointsOfInterest = [PointOfInterest]()
  var isPopulated = false

  init(
    definition: MapDefinition,
    size: BLSize,
    paletteName: String,
    resources: ResourceCollectionProtocol,
    terminal: BLTerminalInterface) throws
  {
    self.definition = definition
    self.palette = try PaletteStore(terminal: terminal, resources: resources, name: paletteName)

    self.terrains = try resources.csvMap(name: "terrain") {
      (row: StringBox) -> (Int, Terrain) in
      let id: Int = row["ID"]
      let terrain = Terrain(
        id: row["ID"],
        name: row["Name"],
        char: row["Character"],
        color: row["Color"],
        canSeeThrough: row["See thru?"],
        walkable: row["Walkable?"])
      return (id, terrain)
    }

    self.features = try resources.csvMap(name: "features") {
      (row: StringBox) -> (Int, Feature) in
      let id: Int = row["ID"]
      let feature = Feature(
        id: row["ID"],
        name: row["Name"],
        char: row["Character"],
        color: row["Color"],
        canSeeThrough: row["See thru?"],
        walkable: row["Walkable?"],
        pathable: row["pathable"])
      return (id, feature)
    }

    var featureIdsByName = [String: Int]()
    for feature in features.values {
      featureIdsByName[feature.name] = feature.id
    }
    self.featureIdsByName = featureIdsByName

    self.interactions = try resources.csvMap(name: "interactions") {
      (row: StringBox) -> (Int, Interaction) in
      let name: String = row["Name"]
      guard let id = featureIdsByName[name] else {
        fatalError("Unknown feature name: \(name)")
      }
      let interaction = Interaction(
        name: row["Name"],
        blocksMovement: row["Blocks Movement?"],
        script: row["Script"])
      return (id, interaction)
    }

    self.cells = CodableArray2D<MapCell>(size: size, emptyValue: MapCell.zero)
  }

  convenience init(
    definition: MapDefinition,
    size: BLSize,
    paletteName: String,
    resources: ResourceCollectionProtocol,
    terminal: BLTerminalInterface,
    generator: GeneratorProtocol) throws
  {
    try self.init(
      definition: definition,
      size: size,
      paletteName: paletteName,
      resources: resources,
      terminal: terminal)
    for y in 0..<generator.cells.size.h {
      for x in 0..<generator.cells.size.w {
        let point = BLPoint(x: x, y: y)
        self.cells[point] = MapCell(generatorCell: generator.cells[point])
      }
    }
  }

  func getIsPassable(entity: Entity, point: BLPoint) -> Bool {
    return self.terrain(at: point)?.walkable == true &&
      (self.feature(at: point) == nil || self.feature(at: point)?.walkable == true)
  }

  func getIsPathable(point: BLPoint) -> Bool {
    return self.feature(at: point)?.pathable == true
  }

  func terrain(at point: BLPoint) -> Terrain? {
    guard let cell = self.cells[point] else { return nil }
    return self.terrains[cell.terrain]
  }

  func feature(at point: BLPoint) -> Feature? {
    guard let cell = self.cells[point] else { return nil }
    return self.features[cell.feature]
  }

  func descriptionOfRoom(coveringCellAt point: BLPoint) -> String? {
    guard let pid = self.cells[point]?.prefabId else { return nil }
    let desc = resources.csvDB.prefabs[pid]?.description ?? ""
//    return desc.isEmpty ? pid : desc
    return desc
  }
}

protocol BLTDrawable {
  var size: BLSize { get }
  var layerIndices: [Int] { get }
  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface)
}
extension BLTDrawable {
  func draw(in terminal: BLTerminalInterface, at point: BLPoint) {
    for layerIndex in layerIndices {
      terminal.layer = Int32(layerIndex)
      for innerPoint in BLRect(size: size) {
        self.draw(layer: layerIndex, offset: point, point: innerPoint, terminal: terminal)
      }
    }
  }
}

extension LevelMap: BLTDrawable {
  var size: BLSize { return cells.size }
  var layerIndices: [Int] { return [0] }
  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface) {
    self.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: true)
  }

  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface, live: Bool) {
    guard let cell = self.cells[point] else { return }
    if let feature = features[cell.feature] {
      terminal.foregroundColor = (live || cell.feature == 4) ? palette[feature.color] : palette["level_memory"]
      terminal.put(point: point + offset, code: BLInt(feature.char))
    } else if let terrain = terrains[cell.terrain] {
      terminal.foregroundColor = live ? palette[terrain.color] : palette["level_memory"]
      terminal.put(point: point + offset, code: BLInt(terrain.char))
    }
  }
}
