import Foundation

print("Launched")

let xpFileURL = URL(string: "file:///Users/steve/_d/games/RogueKit/Resources/xptest.xp")!
if let data = try? Data(contentsOf: xpFileURL),
  let image = REXPaintImage(maybeGzippedData: data) {
  print("Loaded", xpFileURL, image)
  runTest(rexPaintImage: image, fontPath: "/Users/steve/_d/games/RogueKit/Resources/cp437_10x10.png")
}
