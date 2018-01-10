//
//  test.swift
//  RLSandbox
//
//  Created by Steve Johnson on 1/5/18.
//  Copyright © 2018 Steve Johnson. All rights reserved.
//

import BearLibTerminal

func runTest(rexPaintImage: REXPaintDrawable, fontPath: String) {
    let terminal = BLTerminal.main

    terminal.open()
    let result = terminal.configure("""
    window.title='RogueKit Test';
    font: \(fontPath), size=10x10;
    """)
    assert(result == true)
    terminal.clear()
    terminal.refresh()

    // Draw red text with cyan background
    let red = terminal.getColor(name: "flame")
    terminal.foregroundColor = red
    terminal.backgroundColor = terminal.getColor(a: 255, r: 0, g: 255, b: 255)
    assert(terminal.foregroundColor == red)
    assert(terminal.backgroundColor == 0xFF00FFFF)
    terminal.print(point: BLPoint.zero, string: "flame text")
    assert(terminal.pickCode(point: BLPoint.zero, index: 0) == 102)
    assert(terminal.pickForegroundColor(point: BLPoint.zero, index: 0) == red)
    assert(terminal.pickBackgroundColor(point: BLPoint.zero, index: 0) == terminal.getColor(a: 255, r: 0, g: 255, b: 255))

    // Draw two characters on top of each other with compositing, then turn off compositing
    terminal.foregroundColor = terminal.getColor(name: "white")
    terminal.backgroundColor = terminal.getColor(name: "black")
    terminal.isCompositionEnabled = true
    assert(terminal.isCompositionEnabled == true)
    terminal.print(point: BLPoint(x: 0, y: 1), string: "-")
    terminal.print(point: BLPoint(x: 0, y: 1), string: "O")
    terminal.isCompositionEnabled = false
    assert(terminal.isCompositionEnabled == false)
    terminal.print(point: BLPoint(x: 1, y: 1), string: "-")
    terminal.print(point: BLPoint(x: 1, y: 1), string: "O")

    // Draw two layers. Clear part of the second.
    terminal.print(point: BLPoint(x: 0, y: 2), string: "----\n----\n----\n----")
    terminal.layer = 1
    assert(terminal.layer == 1)
    terminal.print(point: BLPoint(x: 0, y: 2), string: "____\n____\n____\n____")
    terminal.clear(area: BLRect(x: 2, y: 4, w: 2, h: 2))
    terminal.layer = 0

    // Crop to a predefined area
    terminal.crop(area: BLRect(x: 1, y: 8, w: 1, h: 1))
    // DOESN'T WOBL???
    terminal.print(point: BLPoint(x: 0, y: 7), string: "---\n---\n---")
    terminal.crop(area: BLRect(x: 1, y: 8, w: 0, h: 0))

    terminal.put(point: BLPoint(x: 0, y: 11), code: Int32("X".utf8CString[0]))
    terminal.foregroundColor = 0
    terminal.backgroundColor = terminal.getColor(name: "white")
    terminal.put(
        point: BLPoint(x: 1, y: 11),
        code: Int32("X".utf8CString[0]),
        offset: BLPoint(x: 3, y: 3),
        nw: terminal.getColor(a: 255, r: 255, g: 255, b: 255),
        sw: terminal.getColor(a: 255, r: 0, g: 255, b: 255),
        se: terminal.getColor(a: 255, r: 255, g: 0, b: 255),
        ne: terminal.getColor(a: 255, r: 255, g: 255, b: 0))
    terminal.foregroundColor = terminal.getColor(name: "white")
    terminal.backgroundColor = terminal.getColor(name: "black")

    terminal.print(point: BLPoint(x: 20, y: 0), string: "[color=red]Fancy print[/color]")
    assert(terminal.measure(string: "Fancy print") == BLSize(w: 11, h: 1))

    // Can haz REXPaint?
    rexPaintImage.draw(in: terminal, at: BLPoint(x: 0, y: 13))

    terminal.refresh()

    terminal.delay(milliseconds: 1000)
    terminal.foregroundColor = terminal.getColor(a: 255, r: 255, g: 255, b: 255)
    terminal.backgroundColor = terminal.getColor(a: 0, r: 0, g: 0, b: 0)
    terminal.print(point: BLPoint(x: 20, y: 1), string: "Enter a string:")
    terminal.refresh()

    if let s = terminal.readString(point: BLPoint(x: 20, y: 2), max: 100) {
      terminal.print(point: BLPoint(x: 20, y: 2), string: "> \(s)")
    } else {
      terminal.print(point: BLPoint(x: 20, y: 2), string: "> (no text)")
    }
    terminal.refresh()

    terminal.waitForExit()
}
