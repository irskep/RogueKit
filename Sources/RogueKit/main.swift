/*
 Screen is 106x60
 Map is 80x50
 */

import Foundation
import BearLibTerminal
#if os(OSX)
  import AppKit
#endif

struct Config: Codable {
  var keyLeft: Int32 = BLConstant.LEFT
  var keyRight: Int32 = BLConstant.RIGHT
  var keyUp: Int32 = BLConstant.UP
  var keyDown: Int32 = BLConstant.DOWN
  var keyWait: Int32 = BLConstant.SPACE
  var keyInventoryOpen: Int32 = BLConstant.I
  var keyEquip: Int32 = BLConstant.E
  var keyDrop: Int32 = BLConstant.D
  var keyRangedFire: Int32 = BLConstant.ENTER
  var keyToggleInspectedEntity: Int32 = BLConstant.TAB

  var keyDebugLeft: Int32 = BLConstant.MINUS
  var keyDebugRight: Int32 = BLConstant.EQUALS
  var keyDebugOmniscience: Int32 = BLConstant._1

  var keyMenu: Int32 = BLConstant.ESCAPE
  var keyExit: Int32 = BLConstant.Q
}

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

#if os(OSX)
  import AppKit
  let isScreenBigEnough = (NSScreen.main?.frame.size.height ?? 1000) > 720
#else
  let isScreenBigEnough = false
#endif

//let FONT = "fonts/Alloy_curses_12x12.png"
let FONT = "fonts/font_12x12.png"
//let FONT = "fonts/cp437_10x10.png"
let FONT_SIZE = FONT[FONT.index(FONT.endIndex, offsetBy: -9)..<FONT.index(FONT.endIndex, offsetBy: -4)]

private let director = SteveRLDirector(terminal: terminal, configBlock: {
  let config = """
  window.title='RogueKit Test';
  font: \(resources.path(for: FONT)), size=\(FONT_SIZE);
  input.filter=keyboard,mouse;
  window.size=106x60;
  window.resizeable=false;
  window.fullscreen=\(isScreenBigEnough ? false : true);
  """
  print("\n" + config + "\n")
  let result = $0.configure(config)
  assert(result == true)
})

#if os(OSX)
  // Move the window to the upper right corner of the screen so it doesn't
  // block Xcode
  terminal.refresh()
  if let window = NSApp.windows.first,
    let screen = window.screen,
    // ...but only do that if we're probably on my computer
    FileManager.default.fileExists(atPath: "/Users/steve/_d/games/RogueKit/Readme.md")
  {
    window.setFrameOrigin(NSPoint(
      x: screen.frame.size.width - window.frame.size.width - 11,
      y: screen.frame.size.height - window.frame.size.height - 9 - (NSApp.mainMenu?.menuBarHeight ?? 20)))
  }
#endif

//director.run(initialScene: LoadScene(
//  rngStore: RandomSeedStore(seed: 135205160),
//  resources: resources,
//  id: "basic"))
director.run(initialScene: TitleScene(resources: resources))
while !director.shouldExit {
  director.iterate()
  terminal.delay(milliseconds: 12)
//  Thread.sleep(forTimeInterval: 0.0125)
}
terminal.close()
NSLog("exit")

