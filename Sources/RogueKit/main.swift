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
  window.size=80x40;
  """)
assert(result == true)

func testEverything() throws {
  let reader = GeneratorReader(resources: resources)
  var loadingY: Int32 = 0
  try reader.run(id: "basic", rng: RKGetRNG(seed: 135205161)) {
    gen, status, result in
    print(status)
//    if result == nil && false {
//      terminal.foregroundColor = terminal.getColor(name: "white")
//      terminal.backgroundColor = terminal.getColor(name: "black")
//      terminal.print(point: BLPoint(x: 0, y: loadingY), string: status)
//      terminal.refresh()
//      loadingY += 1
//    } else {
      terminal.clear()
      gen.draw(in: terminal, at: BLPoint.zero)
      terminal.layer = 2
      gen.debugDistanceField?.draw(in: terminal, at: BLPoint.zero)
      terminal.layer = 1
//      (gen as! PurePrefabGenerator).drawOpenPorts(in: terminal)
      terminal.refresh()
//    }
  }
}

func testGenerator() {
  let gen = PurePrefabGenerator(rng: RKRNG(), resources: resources, size: BLSize(w: 80, h: 40))
  gen.start()

  let draw: () -> () = {
    terminal.clear()
    gen.recommitEverything()
    gen.draw(in: terminal, at: BLPoint.zero)
    terminal.refresh()
  }
  draw()

  //terminal.read()
  for _ in 0..<500 {
    gen.iterate()
  //  draw()
  //  _ = terminal.read()
  }

  draw()
  //_ = terminal.read()

    //gen.drawOpenPorts(in: terminal)
    //terminal.refresh()
    //terminal.read()

  gen.connectAdjacentPorts()
  draw()
  //_ = terminal.read()

  gen.removeDeadEnds()
  draw()

  for _ in 0..<500 {
    gen.iterate()
  }
  gen.removeDeadEnds()
  draw()
  _ = terminal.read()

  for _ in 0..<5 {
    print("adding a hallway")
    gen.addHallwayToPortFurthestFromACycle(numIterations: 1)
  }
  gen.draw(in: terminal, at: BLPoint.zero)
  terminal.refresh()
  //terminal.layer = 2
  //gen.debugDistanceField?.draw(in: terminal, at: BLPoint.zero)
  //terminal.refresh()
}

try testEverything()

terminal.waitForExit()
