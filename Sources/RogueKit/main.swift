import Foundation
import BearLibTerminal

print("Launched")

var path = ""
if CommandLine.arguments.count > 1 {
  path = CommandLine.arguments[1]
}
if !FileManager.default.fileExists(atPath: path) {
  path = Bundle.main.resourcePath! + "/Resources"
}
NSLog("\(path)")
let resources = ResourceCollection(path: path)
let terminal = BLTerminal.main
terminal.open()

let result = terminal.configure("""
  window.title='RogueKit Test';
  font: \(resources.path(for: "fonts/cp437_10x10.png")), size=10x10;
  window.size=80x40;
  """)
assert(result == true)

func load(seed: UInt32, id: String, onComplete: (LevelMap) -> Void) throws {
  let reader = GeneratorReader(resources: resources)
  try reader.run(id: id, rng: RKGetRNG(seed: seed)) {
    gen, status, result in
    terminal.clear()
    terminal.layer = 0
    gen.draw(in: terminal, at: BLPoint.zero)
    terminal.layer = 2
    gen.debugDistanceField?.draw(in: terminal, at: BLPoint.zero)
    terminal.refresh()

    if result != nil {
      onComplete(try LevelMap(
        size: gen.cells.size,
        resources: resources,
        terminal: terminal,
        generator: gen))
    }
  }
}

func play(map: LevelMap) {
  terminal.layer = 0
  terminal.clear()
  map.draw(in: terminal, at: BLPoint.zero)
  terminal.refresh()
}

var delta = 0
func run() throws {
  try load(seed: UInt32(delta + 135205160), id: "basic") {
    play(map: $0)
  }
}

try run()

outer: while true {
  let val = terminal.read()
  switch val {
  case BLConstant.CLOSE:
    break outer
  case BLConstant.LEFT:
    delta -= 1
    try run()
  case BLConstant.RIGHT:
    delta += 1
    try run()
  default: break
  }
}
terminal.close()
