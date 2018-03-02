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


class SteveRLDirector: Director {
  let config = Config()
}

let director = SteveRLDirector(terminal: terminal, configBlock: {
  let config = """
  window.title='RogueKit Test';
  font: \(resources.path(for: "fonts/cp437_10x10.png")), size=10x10;
  window.size=80x40;
  """
  print(config)
  let result = $0.configure(config)
  assert(result == true)
})


class LoadScene: Scene {
  let rngStore: RandomSeedStore
  let id: String
  let resources: ResourceCollection

  var terminal: BLTerminalInterface? { return director?.terminal }

  init(rngStore: RandomSeedStore, resources: ResourceCollection, id: String) {
    self.rngStore = rngStore
    self.id = id
    self.resources = resources
  }

  var nextScene: Scene?

  override func update(terminal: BLTerminalInterface) {
    if let nextScene = nextScene {
      director?.transition(to: nextScene)
      return
    }

    let rng = rngStore[id]
    let reader = GeneratorReader(resources: resources)
    try! reader.run(id: id, rng: rng) {
      gen, status, result in
      print(status)

      guard self.director?.activeScene === self else { return }

      terminal.clear()
      terminal.layer = 0
      gen.draw(in: terminal, at: BLPoint.zero)
      terminal.layer = 2
      gen.debugDistanceField?.draw(in: terminal, at: BLPoint.zero)
      terminal.refresh()

      if result != nil {
        let levelMap = try LevelMap(
          size: gen.cells.size,
          paletteName: "default",
          resources: resources,
          terminal: terminal,
          generator: gen)
        let world = WorldModel(rngStore: rngStore, map: levelMap)
        self.nextScene = LevelScene(resources: self.resources, worldModel: world)
      }
    }
  }
}


class LevelScene: Scene {
  let worldModel: WorldModel
  let resources: ResourceCollection

  var isDirty = false
  
  init(resources: ResourceCollection, worldModel: WorldModel) {
    self.worldModel = worldModel
    self.resources = resources
  }

  override func update(terminal: BLTerminalInterface) {
    isDirty = true
    if terminal.hasInput, let config = (director as? SteveRLDirector)?.config {
      switch terminal.read() {
      case config.keyLeft: worldModel.movePlayer(by: BLPoint(x: -1, y: 0))
      case config.keyRight: worldModel.movePlayer(by: BLPoint(x: 1, y: 0))
      case config.keyUp: worldModel.movePlayer(by: BLPoint(x: 0, y: -1))
      case config.keyDown: worldModel.movePlayer(by: BLPoint(x: 0, y: 1))
      case config.keyDebugLeft:
        director?.transition(to: LoadScene(rngStore: RandomSeedStore(seed: worldModel.rngStore.seed - 1), resources: resources, id: "basic"))
      case config.keyDebugRight:
        director?.transition(to: LoadScene(rngStore: RandomSeedStore(seed: worldModel.rngStore.seed + 1), resources: resources, id: "basic"))
      case BLConstant.CLOSE:
        director?.quit()
      default:
        isDirty = false
      }
    }

    if isDirty {
      terminal.layer = 0
      terminal.clear()
      worldModel.draw(in: terminal, at: BLPoint.zero)
      terminal.refresh()
    }
  }
}


director.run(initialScene: LoadScene(
  rngStore: RandomSeedStore(seed: 135205160),
  resources: resources,
  id: "basic"))
while !director.shouldExit {
  director.iterate()
  Thread.sleep(forTimeInterval: 0.0125)
}
terminal.close()
print("exit")

//#if os(OSX)
//  import AppKit
//  AppKit.RunLoop.main.run()
//  NSApp.run()
//#endif

