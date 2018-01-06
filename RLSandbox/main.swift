//
//  main.swift
//  RLSandbox
//
//  Created by Steve Johnson on 1/2/18.
//  Copyright © 2018 Steve Johnson. All rights reserved.
//

import Foundation


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

struct Cell {
    var terrain: Terrain
}

class TileMap {
    var cells = [RKPoint: Cell]()

    func get(_ point: RKPoint) -> Cell? {
        return cells[point]
    }

    func put(_ point: RKPoint, _ cell: Cell) {
        cells[point] = cell
    }
}

func getAllowsLight(_ tilemap: TileMap, _ point: RKPoint) -> Bool {
    guard let cell = tilemap.get(point) else { return false }
    return cell.terrain == .floor
}

func draw(terminal: RKTerminalInterface, tilemap: TileMap, playerPos: RKPoint) {
    let losCache = RecursiveShadowcastingFOVProvider()
        .getVisiblePoints(vantagePoint: playerPos, maxDistance: 30, getAllowsLight: {
            return getAllowsLight(tilemap, $0)
        })

    for (pt, cell) in tilemap.cells {
        if losCache.contains(pt) {
            terminal.print(point: pt, string: String([cell.terrain.rawValue]))
        } else {
            terminal.print(point: pt, string: " ")
        }
    }
    terminal.print(point: playerPos, string: "@")
}

func main() {
    let terminal = RKTerminal.main
    terminal.open()

    let tilemap = TileMap()
    var playerPos = RKPoint(x: 0, y: 0)
    for (y, row) in DUNGEON.enumerated() {
        for (x, char) in row.enumerated() {
            tilemap.put(RKPoint(x: Int32(x), y: Int32(y)), Cell(terrain: Terrain(rawValue: char) ?? .floor))
            if char == "@" {
                playerPos = RKPoint(x: Int32(x), y: Int32(y))
            }
        }
    }

    mainLoop: while true {
        terminal.clear()
        draw(terminal: terminal, tilemap: tilemap, playerPos: playerPos)
        terminal.refresh()

        if terminal.hasInput {
            switch terminal.read() {
            case RKConstant.Q, RKConstant.CLOSE: break mainLoop
            case RKConstant.UP: playerPos.y -= 1
            case RKConstant.DOWN: playerPos.y += 1
            case RKConstant.LEFT: playerPos.x -= 1
            case RKConstant.RIGHT: playerPos.x += 1
            default: break
            }
        }
    }

    terminal.close()
}

runTest()

