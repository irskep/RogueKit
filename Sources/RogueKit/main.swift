import Foundation
import BearLibTerminal

print("Launched")

//let RESOURES_PATH = "/Users/steve/_d/games/RogueKit/Resources"
//
//extension REXPaintImage {
//  convenience init?(name: String) {
//    guard let url = URL(string: "file://\(RESOURES_PATH)/xp/\(name).xp") else { return nil }
//    guard let data = try? Data(contentsOf: url) else {
//      print("Error loading", url)
//      return nil
//    }
//    self.init(maybeGzippedData: data)
//  }
//}
//
//let sprites = SpriteSheet(image: REXPaintImage(name: "fabs")!).sprites
//
//runTest(rexPaintImage: REXPaintImage(name: "xptest")!, fontPath: "\(RESOURES_PATH)/cp437_10x10.png")

let resources = ResourceCollection()
let terminal = BLTerminal.main
terminal.open()

let result = terminal.configure("""
  window.title='RogueKit Test';
  font: \(resources.path(for: "fonts/cp437_10x10.png")), size=10x10;
  window.size=80x80;
  """)
assert(result == true)

let gen = PurePrefabGenerator(rng: RKRNG(), resources: resources, size: BLSize(w: 80, h: 80))
gen.start()
gen.draw(in: terminal, at: BLPoint.zero)
terminal.refresh()
//terminal.read()
for _ in 0..<300 {
  gen.iterate()
//  terminal.clear()
//  gen.draw(in: terminal, at: BLPoint.zero)
//  gen.drawOpenPorts(in: terminal)
//  terminal.refresh()
}

gen.draw(in: terminal, at: BLPoint.zero)
gen.drawOpenPorts(in: terminal)
terminal.refresh()

terminal.read()
gen.connectAdjacentPorts()
gen.draw(in: terminal, at: BLPoint.zero)
terminal.refresh()

terminal.waitForExit()
