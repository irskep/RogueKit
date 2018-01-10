//
//  Fab.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/9/18.
//

import Foundation
import BearLibTerminal


private struct CP437 {
  static let LINE_NW = 218
  static let LINE_NE = 191
  static let LINE_SW = 192
  static let LINE_SE = 217
  static let LINE_H = 196
  static let LINE_V = 179

  static let ARROW_W = 27
  static let ARROW_E = 26
  static let ARROW_N = 24
  static let ARROW_S = 25
}


private func _findSprites(in image: REXPaintImage) -> [REXPaintSprite] {
  var used = [[Bool]](repeating: [Bool](repeating: false, count: Int(image.width)), count: Int(image.height))
  var sprites = [REXPaintSprite]()

  let readSprite = {
    (x: Int32, y: Int32) -> Void in
    var w: Int32 = 0
    var h: Int32 = 0
    var x2 = x + 1
    var nameChars = [Int32]()
    var isReadingName = true
    while image.get(layer: 1, x: Int(x2), y: Int(y)).code != CP437.LINE_NE {
      let code = image.get(layer: 1, x: Int(x2), y: Int(y)).code
      if isReadingName {
        if code == CP437.LINE_H {
          isReadingName = false
        } else {
          nameChars.append(code)
        }
      }
      x2 += 1
      w += 1
    }
    var y2 = y + 1
    while image.get(layer: 1, x: Int(x), y: Int(y2)).code != CP437.LINE_SW {
      y2 += 1
      h += 1
    }


    let nameString: String = nameChars
      .flatMap({
        guard let s = UnicodeScalar(Int($0)) else { return nil }
        return String(Character(s))
      })
      .joined()
    sprites.append(REXPaintSprite(image: image, rect: BLRect(x: x + 1, y: y + 1, w: w, h: h), name: nameString))
  }

  for y in 0..<image.height {
    for x in 0..<image.width {
      if used[Int(y)][Int(x)] { continue }
      let cell = image.get(layer: 1, x: Int(x), y: Int(y))
      if cell.code == CP437.LINE_NW {
        readSprite(x, y)
      }
    }
  }
//  print(image.width, image.height)
//  print(image.layers)
  return sprites
}


class SpriteSheet {
  var image: REXPaintImage
  lazy var sprites: [REXPaintSprite] = { return _findSprites(in: self.image) }()

  init(image: REXPaintImage) {
    self.image = image
  }
}

struct REXPaintSprite: REXPaintDrawable {
  let image: REXPaintImage
  let rect: BLRect
  let name: String

  var layersCount: Int { return image.layersCount }
  var width: Int32 { return rect.w }
  var height: Int32 { return rect.h }

  func get(layer: Int, point: BLPoint) -> REXPaintCell {
    return image.get(layer: layer, x: Int(point.x + rect.x), y: Int(point.y + rect.y))
  }

  func get(layer: Int, x: Int, y: Int) -> REXPaintCell {
    return image.get(layer: layer, x: x + Int(rect.x), y: y + Int(rect.y))
  }
}
