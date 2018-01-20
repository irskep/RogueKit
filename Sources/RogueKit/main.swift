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
