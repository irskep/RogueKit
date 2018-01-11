//
//  REXPaintImage+BearLibTerminal.swift
//
//  Copyright (c) 2018, Steve Johnson
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import BearLibTerminal


public protocol REXPaintDrawable {
  var width: Int32 { get }
  var height: Int32 { get }
  var layersCount: Int { get }
  func get(layer: Int, x: Int, y: Int) -> REXPaintCell
}

public extension REXPaintDrawable {
  public func draw(in terminal: BLTerminalInterface, at point: BLPoint) {
    let transparent = terminal.getColor(a: 255, r: 255, g: 0, b: 255)
    let wasCompositing = terminal.isCompositionEnabled
    if layersCount > 1 { terminal.isCompositionEnabled = true }
    for layer in 0..<layersCount {
      for y in 0..<height {
        for x in 0..<width {
          let cell = self.get(layer: layer, x: Int(x), y: Int(y))
          if cell.code == 0 { continue }

          let fg = terminal.getColor(a: 255, r: cell.foregroundColor.0, g: cell.foregroundColor.1, b: cell.foregroundColor.2)
          terminal.foregroundColor = fg

          let bg = terminal.getColor(a: 255, r: cell.backgroundColor.0, g: cell.backgroundColor.1, b: cell.backgroundColor.2)
          if bg == transparent {
            terminal.backgroundColor = terminal.getColor(a: 0, r: 0, g: 0, b: 0)
          } else {
            terminal.backgroundColor = bg
          }
          terminal.put(point: point + BLPoint(x: x, y: y), code: cell.code)
        }
      }
    }
    terminal.isCompositionEnabled = wasCompositing
  }
}

extension REXPaintImage: REXPaintDrawable {
  public var layersCount: Int { return layers.count }
}
