//
//  main.swift
//  RLSandbox
//
//  Created by Steve Johnson on 1/2/18.
//  Copyright © 2018 Steve Johnson. All rights reserved.
//

import Foundation
import BearLibTerminal
import GameplayKit

let DUNGEON: [String] = [
  "###########################################################",
  "#...........#.............................................#",
  "#...........#........#....................................#",
  "#.....................#...................................#",
  "#....####..............#..................................#",
  "#.......#.......................#####################.....#",
  "#.......#...........................................#.....#",
  "#.......#...........##..............................#.....#",
  "#####........#......##.....@....##################..#.....#",
  "#...#...........................#................#..#.....#",
  "#...#............#..............#................#..#.....#",
  "#...............................#..###############..#.....#",
  "#...............................#...................#.....#",
  "#...............................#...................#.....#",
  "#...............................#####################.....#",
  "#.........................................................#",
  "#.........................................................#",
  "###########################################################",
]

enum Terrain: Character {
  case floor = "."
  case wall = "#"

  var cString: ContiguousArray<CChar> { return String([rawValue]).utf8CString }
}
extension int2: Hashable {
  public var hashValue: Int {
    return x.hashValue &* 31 &+ y.hashValue
  }
}

struct Cell {
  var terrain: Terrain
}

class TileMap {
  var cells = [int2: Cell]()

  func get(_ point: int2) -> Cell? {
    return cells[point]
  }

  func put(_ point: int2, _ cell: Cell) {
    cells[point] = cell
  }
}

func getAllowsLight(_ tilemap: TileMap, _ point: int2) -> Bool {
  guard let cell = tilemap.get(point) else { return false }
  return cell.terrain == .floor
}

func draw(tilemap: TileMap, playerPos: int2) {
  let losCache = RecursiveShadowcastingFOVProvider()
    .getVisiblePoints(vantagePoint: playerPos, maxDistance: 30, getAllowsLight: {
      return getAllowsLight(tilemap, $0)
    })

  let space = Array<Int8>(" ".utf8CString)
  for (pt, cell) in tilemap.cells {
    if losCache.contains(pt) {
      let chr = Array<Int8>(cell.terrain.cString)
      terminal_print(pt.x, pt.y, UnsafePointer(chr))
    } else {
      terminal_print(pt.x, pt.y, UnsafePointer(space))
    }
  }
  let chr = Array<Int8>("@".utf8CString)
  terminal_print(playerPos.x, playerPos.y, UnsafePointer(chr))
}

func main() {
  terminal_open()

  let tilemap = TileMap()
  var playerPos = int2(0, 0)
  for (y, row) in DUNGEON.enumerated() {
    for (x, char) in row.enumerated() {
      tilemap.put(int2(Int32(x), Int32(y)), Cell(terrain: Terrain(rawValue: char) ?? .floor))
      if char == "@" {
        playerPos = int2(Int32(x), Int32(y))
      }
    }
  }

  mainLoop: while true {
    terminal_clear()
    draw(tilemap: tilemap, playerPos: playerPos)
    terminal_refresh()

    if terminal_has_input() != 0 {
      switch terminal_read() {
      case TK_Q, TK_CLOSE: break mainLoop
      case TK_UP: playerPos.y -= 1
      case TK_DOWN: playerPos.y += 1
      case TK_LEFT: playerPos.x -= 1
      case TK_RIGHT: playerPos.x += 1
      default: break
      }
    }
  }

  terminal_close()
}

main()
