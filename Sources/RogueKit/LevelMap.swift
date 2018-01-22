//
//  LevelMap.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/20/18.
//

import Foundation
import BearLibTerminal

struct Terrain {
  let id: Int
  let name: String
  let char: Int
  let color: BLColor
}


struct Feature {
  let id: Int
  let name: String
  let char: Int
  let color: BLColor
}

struct MapCell {
  var terrain: Int
  var feature: Int

  static let zero = { return MapCell(terrain: 0, feature: 0) }()
}

extension MapCell {
  init(generatorCell: GeneratorCell) {
    if generatorCell.flags.contains(.portUsed) {
      self.terrain = 1
      self.feature = 2
      return
    }
    self.feature = 0
    switch generatorCell.basicType {
    case .empty:
      self.terrain = 0
    case .floor:
      self.terrain = 1
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
        color: terminal.getColor(name: row["Color"]))
      return (id, terrain)
    }
    self.features = try resources.csvMap(name: "features") {
      (row: StringBox) -> (Int, Feature) in
      let id: Int = row["ID"]
      let feature = Feature(
        id: row["ID"],
        name: row["Name"],
        char: row["Character"],
        color: terminal.getColor(name: row["Color"]))
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
    print(terrains)
    print(features)
    print(self.cells)
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
      print("f", feature)
      terminal.foregroundColor = feature.color
      terminal.put(point: point + offset, code: BLInt(feature.char))
    } else if let terrain = terrains[cell.terrain] {
      print("t", terrain)
      terminal.foregroundColor = terrain.color
      terminal.put(point: point + offset, code: BLInt(terrain.char))
    }
  }
}
