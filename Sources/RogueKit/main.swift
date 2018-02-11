import Foundation
import BearLibTerminal

struct Config: Codable {
  var keyLeft: Int32 = BLConstant.LEFT
  var keyRight: Int32 = BLConstant.RIGHT
  var keyUp: Int32 = BLConstant.UP
  var keyDown: Int32 = BLConstant.DOWN

  var keyDebugLeft: Int32 = BLConstant.MINUS
  var keyDebugRight: Int32 = BLConstant.EQUALS
}

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

func load(rng: RKRNGProtocol, id: String, onComplete: (LevelMap) -> Void) throws {
  let reader = GeneratorReader(resources: resources)
  try reader.run(id: id, rng: rng) {
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
        paletteName: "default",
        resources: resources,
        terminal: terminal,
        generator: gen))
    }
  }
}

func run(config: Config) throws {
  var delta = 0

  var rng: RKRNGProtocol! = nil
  var world: WorldModel! = nil

  let reload = {
    rng = RKGetRNG(seed: UInt32(delta + 135205160))
    try load(rng: rng, id: "basic") {
      world = WorldModel(random: rng, map: $0)
    }
  }

  try reload()

  var isDirty = true
  while true {
    if isDirty {
      terminal.layer = 0
      terminal.clear()
      world.draw(in: terminal, at: BLPoint.zero)
      terminal.refresh()
    }
    isDirty = true

    switch terminal.read() {
    case config.keyLeft: world.movePlayer(by: BLPoint(x: -1, y: 0))
    case config.keyRight: world.movePlayer(by: BLPoint(x: 1, y: 0))
    case config.keyUp: world.movePlayer(by: BLPoint(x: 0, y: -1))
    case config.keyDown: world.movePlayer(by: BLPoint(x: 0, y: 1))
    case config.keyDebugLeft:
      delta -= 1
      try reload()
    case config.keyDebugRight:
      delta += 1
      try reload()
    case BLConstant.CLOSE:
      return
    default:
      isDirty = false
      continue
    }
  }
}

try run(config: Config())
terminal.close()
