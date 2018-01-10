//
//  REXPaintImage.swift
//
//  Created by Steve Johnson on 1/7/18.
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

// Requires Gzip package:
// https://github.com/1024jp/GzipSwift
import Gzip


public class REXPaintImage: CustomDebugStringConvertible {
  public let version: Int32
  public let layers: [[REXPaintCell]]
  public let width: Int32
  public let height: Int32

  public init?(maybeGzippedData: Data) {
    var data = maybeGzippedData
    if data.isGzipped {
      guard let decompressedData = try? data.gunzipped() else { return nil }
      data = decompressedData
    }
    let ints: [Int32] = data.withUnsafeBytes {
      Array(UnsafeBufferPointer<Int32>(start: $0, count: data.count/MemoryLayout<Int32>.size))
    }

    // Read the preamble
    self.version = ints[0]
    let layersCount = ints[1]
    self.width = ints[2]
    self.height = ints[3]
    let cellsPerLayer = Int(self.width * self.height)

    print(layersCount)

    // Initialize layers array
    var layers = [[REXPaintCell]]()

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
        layerArr[cellIndex] = REXPaintCell(
          code: code,
          foregroundColor: (cellBytes[4], cellBytes[5], cellBytes[6]),
          backgroundColor: (cellBytes[7], cellBytes[8], cellBytes[9]))
      }
      layers.append(layerArr)
    }
    self.layers = layers
  }

  public func get(layer: Int, x: Int, y: Int) -> REXPaintCell {
    return layers[layer][x * Int(self.height) + y]
  }

  public var debugDescription: String {
    return "REXPaintImage(w=\(self.width), h=\(self.width), layers=\(self.layers.count))"
  }
}


public struct REXPaintCell {
  public let code: Int32
  public let foregroundColor: (UInt8, UInt8, UInt8)
  public let backgroundColor: (UInt8, UInt8, UInt8)

  public static let zero = { return REXPaintCell(code: 0, foregroundColor: (0, 0, 0), backgroundColor: (0, 0, 0)) }()

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
