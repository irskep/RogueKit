//
//  main.swift
//  RLSandbox
//
//  Created by Steve Johnson on 1/2/18.
//  Copyright © 2018 Steve Johnson. All rights reserved.
//

import Foundation
import BearLibTerminal


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
    var cells = [BLPoint: Cell]()

    func get(_ point: BLPoint) -> Cell? {
        return cells[point]
    }

    func put(_ point: BLPoint, _ cell: Cell) {
        cells[point] = cell
    }
}

func getAllowsLight(_ tilemap: TileMap, _ point: BLPoint) -> Bool {
    guard let cell = tilemap.get(point) else { return false }
    return cell.terrain == .floor
}

func draw(terminal: BLTerminalInterface, tilemap: TileMap, playerPos: BLPoint) {
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

func fovTest() {
    let terminal = BLTerminal.main
    terminal.open()

    let tilemap = TileMap()
    var playerPos = BLPoint(x: 0, y: 0)
    for (y, row) in DUNGEON.enumerated() {
        for (x, char) in row.enumerated() {
            tilemap.put(BLPoint(x: Int32(x), y: Int32(y)), Cell(terrain: Terrain(rawValue: char) ?? .floor))
            if char == "@" {
                playerPos = BLPoint(x: Int32(x), y: Int32(y))
            }
        }
    }

    mainLoop: while true {
        terminal.clear()
        draw(terminal: terminal, tilemap: tilemap, playerPos: playerPos)
        terminal.refresh()

        if terminal.hasInput {
            switch terminal.read() {
            case BLConstant.Q, BLConstant.CLOSE: break mainLoop
            case BLConstant.UP: playerPos.y -= 1
            case BLConstant.DOWN: playerPos.y += 1
            case BLConstant.LEFT: playerPos.x -= 1
            case BLConstant.RIGHT: playerPos.x += 1
            default: break
            }
        }
    }

    terminal.close()
}

