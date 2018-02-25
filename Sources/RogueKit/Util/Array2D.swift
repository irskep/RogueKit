//
//  Array2D.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/12/18.
//

import Foundation
import BearLibTerminal


struct Array2D<T> {
  var array: Array<T>
  var size: BLSize

  init(size: BLSize, emptyValue: T) {
    self.size = size
    self.array = [T](repeating: emptyValue, count: Int(size.w * size.h))
  }

  subscript(index: BLPoint) -> T {
    get {
      return self.array[Int(index.y * size.w + index.x)]
    }
    set {
      self.array[Int(index.y * size.w + index.x)] = newValue
    }
  }
}

struct CodableArray2D<T: Codable>: Codable {
  var array: Array<T>
  var size: BLSize

  init(size: BLSize, emptyValue: T) {
    self.size = size
    self.array = [T](repeating: emptyValue, count: Int(size.w * size.h))
  }

  subscript(index: BLPoint) -> T? {
    get {
      guard index.x >= 0 && index.x < size.w && index.y >= 0 && index.y < size.h else {
        return nil
      }
      return self.array[Int(index.y * size.w + index.x)]
    }
    set {
      guard let newValue = newValue else { return }
      guard index.x >= 0 && index.x < size.w && index.y >= 0 && index.y < size.h else { return }
      self.array[Int(index.y * size.w + index.x)] = newValue
    }
  }
}
