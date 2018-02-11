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
  let color: BLColor
  let canSeeThrough: Bool
  let walkable: Bool
}


struct Feature: Codable {
  let id: Int
  let name: String
  let char: Int
  let color: BLColor
  let canSeeThrough: Bool
  let walkable: Bool
}

struct Interaction: Codable {
  let name: String
  let blocksMovement: Bool
  let script: String
}

struct MapCell: Codable {
  var terrain: Int
  var feature: Int

  static let zero = { return MapCell(terrain: 0, feature: 0) }()
}

extension MapCell {
  init(generatorCell: GeneratorCell) {
    if generatorCell.flags.contains(.portUsed) &&
       !generatorCell.flags.contains(.invisibleDoor) &&
       generatorCell.flags.contains(.room) {
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


class LevelMap: Codable {
  let terrains: [Int: Terrain]
  let features: [Int: Feature]
  let featureIdsByName: [String: Int]
  let interactions: [Int: Interaction]
  var cells: CodableArray2D<MapCell>

  init(size: BLSize, resources: ResourceCollection, terminal: BLTerminalInterface) throws {

    self.terrains = try resources.csvMap(name: "terrain") {
      (row: StringBox) -> (Int, Terrain) in
      let id: Int = row["ID"]
      let terrain = Terrain(
        id: row["ID"],
        name: row["Name"],
        char: row["Character"],
        color: terminal.getColor(name: row["Color"]),
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
        color: terminal.getColor(name: row["Color"]),
        canSeeThrough: row["See thru?"],
        walkable: row["Walkable?"])
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
    size: BLSize,
    resources: ResourceCollection,
    terminal: BLTerminalInterface,
    generator: GeneratorProtocol) throws
  {
    try self.init(size: size, resources: resources, terminal: terminal)
    for y in 0..<generator.cells.size.h {
      for x in 0..<generator.cells.size.w {
        let point = BLPoint(x: x, y: y)
        self.cells[point] = MapCell(generatorCell: generator.cells[point])
      }
    }
  }

  func getIsPassable(entity: Entity, point: BLPoint) -> Bool {
    let cell = self.cells[point]
    return self.terrains[cell.terrain]?.walkable == true &&
      (self.features[cell.feature] == nil || self.features[cell.feature]?.walkable == true)
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
private var _deadGray: BLColor! = nil
extension LevelMap: BLTDrawable {
  var size: BLSize { return cells.size }
  var layerIndices: [Int] { return [0] }
  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface) {
    self.draw(layer: layer, offset: offset, point: point, terminal: terminal, live: true)
  }

  func draw(layer: Int, offset: BLPoint, point: BLPoint, terminal: BLTerminalInterface, live: Bool) {
    if _deadGray == nil {
      _deadGray = terminal.getColor(a: 255, r: 40, g: 40, b: 40)
    }

    let cell = self.cells[point]
    if let feature = features[cell.feature] {
      terminal.foregroundColor = live ? feature.color : _deadGray
      terminal.put(point: point + offset, code: BLInt(feature.char))
    } else if let terrain = terrains[cell.terrain] {
      terminal.foregroundColor = live ? terrain.color : _deadGray
      terminal.put(point: point + offset, code: BLInt(terrain.char))
    }
  }
}
