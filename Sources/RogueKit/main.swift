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

#if os(OSX)
  // Move the window to the upper right corner of the screen so it doesn't
  // block Xcode
  import AppKit
  terminal.refresh()
  if let window = NSApp.windows.first, let screen = window.screen {
    window.setFrameOrigin(NSPoint(
      x: screen.frame.size.width - window.frame.size.width,
      y: screen.frame.size.height - (NSApp.mainMenu?.menuBarHeight ?? 20)))
  }
#endif

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

