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

let resources = ResourceCollection(path: CommandLine.arguments[1])
let terminal = BLTerminal.main
terminal.open()

let result = terminal.configure("""
  window.title='RogueKit Test';
  font: \(resources.path(for: "fonts/cp437_10x10.png")), size=10x10;
  window.size=80x40;
  """)
assert(result == true)

var seed: UInt32 = 135205160
func testEverything() throws {
  let reader = GeneratorReader(resources: resources)
  var loadingY: Int32 = 0
  try reader.run(id: "basic", rng: RKGetRNG(seed: seed)) {
    gen, status, result in
    print(status)
    if result == nil {
      terminal.layer = 0
      terminal.foregroundColor = terminal.getColor(name: "white")
      terminal.backgroundColor = terminal.getColor(a: 255, r: 0, g: 0, b: 0)
      terminal.print(point: BLPoint(x: 0, y: loadingY), string: status)
      terminal.refresh()
      loadingY += 1
    } else {
      terminal.clear()
      terminal.layer = 0
      gen.draw(in: terminal, at: BLPoint.zero)
      terminal.layer = 2
      gen.debugDistanceField?.draw(in: terminal, at: BLPoint.zero)
//      (gen as! PurePrefabGenerator).drawOpenPorts(in: terminal)
      terminal.refresh()
    }
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

outer: while true {
  let val = terminal.read()
  switch val {
  case BLConstant.CLOSE:
    break outer
  case BLConstant.LEFT:
    seed -= 1
    try testEverything()
  case BLConstant.RIGHT:
    seed += 1
    try testEverything()
  default: break
  }
}
terminal.close()
