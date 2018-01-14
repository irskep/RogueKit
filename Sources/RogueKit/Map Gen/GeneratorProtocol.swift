//
//  GeneratorProtocol.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/14/18.
//

import Foundation

protocol GeneratorProtocol: REXPaintDrawable {
  var cells: Array2D<GeneratorCell> { get }

  func runCommand(cmd: String, args: [String])
}
