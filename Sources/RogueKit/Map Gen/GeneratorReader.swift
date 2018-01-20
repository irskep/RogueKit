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

  func run(id: String, rng: RKRNGProtocol, callback: (GeneratorProtocol, String, Array2D<GeneratorCell>?) -> Void) throws {
    let string = try String(contentsOf: resources.url(for: "levelscripts/\(id).csv")!)

    var gen: GeneratorProtocol?
    var commands = [(String, [String])]()

    string.enumerateLines {
      (line: String, stop: inout Bool) in
      guard !line.starts(with: "#") else { return }
      let values = line.split(separator: ",")
      guard values.count > 0 else { return }
      let cmd = String(values[0])
      let args = values.dropFirst().map({ String($0) })
      if gen == nil {
        switch cmd {
        case "prefabs_and_hallways":
          gen = PurePrefabGenerator(
            rng: rng,
            resources: self.resources,
            size: BLSize(w: Int32(args[0])!, h: Int32(args[1])!))
        default:
          fatalError("Unknown generator: \(values[0])")
        }
      } else {
        commands.append((cmd, args))
      }
    }

    guard let generator = gen else { fatalError("No generator loaded") }
    callback(generator, "Starting", nil)
    var i = 0
    for (cmd, args) in commands {
      i += 1
      generator.runCommand(cmd: cmd, args: args.map({ String($0) }))
      if cmd == "debug" {
        callback(generator, "\(i)/\(commands.count): \(cmd) \(args)", nil)
        continue
      }
      callback(generator, "\(i)/\(commands.count): \(cmd) \(args)", nil)
    }
    callback(generator, "Done", generator.cells)
  }
}
