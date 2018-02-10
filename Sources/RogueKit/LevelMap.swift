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

struct Terrain {
  let id: Int
  let name: String
  let char: Int
  let color: BLColor
  let canSeeThrough: Bool
  let walkable: Bool
}


struct Feature {
  let id: Int
  let name: String
  let char: Int
  let color: BLColor
  let canSeeThrough: Bool
  let walkable: Bool
}

struct MapCell {
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


class LevelMap {
  let terrains: [Int: Terrain]
  let features: [Int: Feature]
  var cells: Array2D<MapCell>

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
    self.cells = Array2D<MapCell>(size: size, emptyValue: MapCell.zero)
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

  func openDoor(at point: BLPoint) {
    self.cells[point].feature = 1  // TODO: de-hack
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
    let cell = self.cells[point]
    if let feature = features[cell.feature] {
      terminal.foregroundColor = feature.color
      terminal.put(point: point + offset, code: BLInt(feature.char))
    } else if let terrain = terrains[cell.terrain] {
      terminal.foregroundColor = terrain.color
      terminal.put(point: point + offset, code: BLInt(terrain.char))
    }
  }
}
