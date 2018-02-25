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
NSLog("Path to Resources/: \(path)")

let resources = ResourceCollection(path: path)
let terminal = BLTerminal.main
terminal.open()

let bltConfig = """
  window.title='RogueKit Test';
  font: \(resources.path(for: "fonts/cp437_10x10.png")), size=10x10;
  window.size=80x40;
  """
print(bltConfig)
let result = terminal.configure(bltConfig)
assert(result == true)

func load(rngStore: RandomSeedStore, id: String, onComplete: (LevelMap) -> Void) throws {
  let rng = rngStore[id]
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
  var gameURL: URL? = nil
  if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
    gameURL = appSupportURL.appendingPathComponent("game.json")
  }

  var delta = 0

  var rngStore: RandomSeedStore! = nil
  var world: WorldModel! = nil

  let reload = {
    let rngStore = RandomSeedStore(seed: UInt64(delta + 135205160))
    try load(rngStore: rngStore, id: "basic") {
      world = WorldModel(rngStore: rngStore, map: $0)
    }
  }

  if false, let gameURL = gameURL, FileManager.default.fileExists(atPath: gameURL.path) {
    let data: Data = try Data(contentsOf: gameURL)
    world = try JSONDecoder().decode(WorldModel.self, from: data)
  } else {
    try reload()
  }

  var isDirty = true
  while true {
    if let gameURL = gameURL {
      do {
        let data = try JSONEncoder().encode(world)
        try data.write(to: gameURL)
      } catch {
        print(error)
        fatalError()
      }
    }

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
