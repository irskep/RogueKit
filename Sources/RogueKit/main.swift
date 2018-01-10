import Foundation

print("Launched")

let RESOURES_PATH = "/Users/steve/_d/games/RogueKit/Resources"

extension REXPaintImage {
  convenience init?(name: String) {
    guard let url = URL(string: "file://\(RESOURES_PATH)/xp/\(name).xp") else { return nil }
    guard let data = try? Data(contentsOf: url) else {
      print("Error loading", url)
      return nil
    }
    self.init(maybeGzippedData: data)
  }
}

let sprites = SpriteSheet(image: REXPaintImage(name: "fabs")!).sprites

runTest(rexPaintImage: REXPaintImage(name: "xptest")!, fontPath: "\(RESOURES_PATH)/cp437_10x10.png")
