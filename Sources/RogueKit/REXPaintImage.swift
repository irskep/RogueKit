//
//  REXPaintImage.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/7/18.
//

import Foundation
//import CZlib


public class REXPaintImage {
  public let version: Int32
  public let layers: [[REXPaintCell]]
  public let width: Int32
  public let height: Int32

  public init(data: Data) {
    let ints: [Int32] = data.withUnsafeBytes {
      Array(UnsafeBufferPointer<Int32>(start: $0, count: data.count/MemoryLayout<Int32>.size))
    }

    // Read the preamble
    self.version = ints[0]
    let layersCount = ints[1]
    self.width = ints[2]
    self.height = ints[3]
    let cellsPerLayer = Int(self.width * self.height)

    // Initialize layers array
    self.layers = [[REXPaintCell]](
      repeating: [REXPaintCell](repeating: REXPaintCell.zero, count: cellsPerLayer),
      count: Int(layersCount))

    // w, h, (code + color) * w * h
    let bytesPerCell = 10
    let bytesPerLayer = 4 + 4 + (bytesPerCell * cellsPerLayer)
    let bytesInPreamble = 8
    for layerIndex in 0..<Int(layersCount) {
      let byteStart = bytesInPreamble + layerIndex * bytesPerLayer
      let cellByteStart = byteStart + 8 // w, h
      var layerArr = [REXPaintCell](repeating: REXPaintCell.zero, count: Int(self.width * self.height))
      for cellIndex in 0..<cellsPerLayer {
        let cellByteIndex = data.index(cellByteStart + bytesPerCell * cellIndex, offsetBy: 0)
        let cellData = data.subdata(in: cellByteIndex..<cellByteIndex.advanced(by: bytesPerCell))
        let code: Int32 = cellData.subdata(in: 0..<4).withUnsafeBytes({
          return Array(UnsafeBufferPointer<Int32>(start: $0, count: 1))[0]
        })
        let cellBytes = [UInt8](cellData)
        layerArr[layerIndex] = REXPaintCell(
          code: code,
          foregroundColor: (cellBytes[4], cellBytes[5], cellBytes[6]),
          backgroundColor: (cellBytes[7], cellBytes[8], cellBytes[9]))
      }
    }
  }

  public func get(x: Int, y: Int) -> REXPaintCell {
    return REXPaintCell(code: 0, foregroundColor: (0, 0, 0), backgroundColor: (0, 0, 0))
  }
}


public struct REXPaintCell {
  public let code: Int32
  public let foregroundColor: (UInt8, UInt8, UInt8)
  public let backgroundColor: (UInt8, UInt8, UInt8)

  static let zero = { return REXPaintCell(code: 0, foregroundColor: (0, 0, 0), backgroundColor: (0, 0, 0)) }()

  public init(
    code: Int32,
    foregroundColor: (UInt8, UInt8, UInt8),
    backgroundColor: (UInt8, UInt8, UInt8))
  {
    self.code = code
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
  }
}
