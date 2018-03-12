//
//  GeneratorReader.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/14/18.
//

import Foundation
import BearLibTerminal


class GeneratorReader {
  let resources: ResourceCollectionProtocol

  init(resources: ResourceCollectionProtocol) {
    self.resources = resources
  }

  func run<T: GeneratorProtocol>(
    id: String,
    rng: RKRNGProtocol,
    factory: @escaping (RKRNGProtocol, ResourceCollectionProtocol, BLSize) -> T,
    callback: (T, String, Array2D<GeneratorCell>?) throws -> Void) throws
  {
    let string = try String(contentsOf: resources.url(for: "levelscripts/\(id).csv")!)

    var gen: T?
    var commands = [(String, [String])]()

    for line in string.split(separator: "\n") {
      guard !line.starts(with: "#") else { continue }
      let values = line.split(separator: ",")
      guard values.count > 0 else { continue }
      let cmd = String(values[0])
      let args = values.dropFirst().map({ String($0) })
      if gen == nil {
        switch cmd {
        case "prefabs_and_hallways":
          gen = factory(rng, self.resources, BLSize(w: Int32(args[0])!, h: Int32(args[1])!))
        default:
          fatalError("Unknown generator: \(values[0])")
        }
      } else {
        commands.append((cmd, args))
      }
    }

    guard let generator = gen else { fatalError("No generator loaded") }
    try callback(generator, "Starting", nil)
    var i = 0
    for (cmd, args) in commands {
      i += 1
      generator.runCommand(cmd: cmd, args: args.map({ String($0) }))
      if cmd == "debug" {
        try callback(generator, "\(i)/\(commands.count): \(cmd) \(args)", nil)
        continue
      }
      try callback(generator, "\(i)/\(commands.count): \(cmd) \(args)", nil)
    }
    try callback(generator, "Done", generator.cells)
  }
}
