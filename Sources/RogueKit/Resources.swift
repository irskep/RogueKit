//
//  Resources.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/10/18.
//

import Foundation


protocol ResourceCollectionProtocol {
  var prefabs: [String: Prefab] { get }
  func path(for name: String) -> String
  func url(for name: String) -> URL?
  func rexPaintImage(named: String) -> REXPaintImage?
}


extension REXPaintImage {
  convenience init?(url: URL) {
    guard let data = try? Data(contentsOf: url) else {
      print("Error loading", url)
      return nil
    }
    self.init(maybeGzippedData: data)
  }
}


class ResourceCollection: ResourceCollectionProtocol {
  let path: String
  
  init(path: String) {
    self.path = path
  }

  lazy var prefabs: [String : Prefab] = {
    guard let image = self.rexPaintImage(named: "fabs") else { return [:] }

    return [String: Prefab](uniqueKeysWithValues: SpriteSheet(image: image)
      .sprites
      .map({ Prefab(sprite: $0) })
      .map({ (p: Prefab) -> (String, Prefab) in (p.sprite.name, p) }))
  }()

  func path(for name: String) -> String {
    return "\(path)/\(name)"
  }

  func url(for name: String) -> URL? {
    return URL(string: "file://\(path)/\(name)")
  }

  func rexPaintImage(named name: String) -> REXPaintImage? {
    guard let url = URL(string: "file://\(self.path)/xp/\(name).xp") else { return nil }
    return REXPaintImage(url: url)
  }
}
