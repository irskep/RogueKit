//
//  CSV.swift
//  RogueKit
//
//  Created by Steve Johnson on 1/21/18.
//

import Foundation


class StringBox {
  let labels: [String]
  let values: [String]
  var labelToIndex = [String: Int]()

  init(labels: [String], values: [String]) {
    self.labels = labels
    self.values = values
    for (i, label) in labels.enumerated() {
      labelToIndex[label] = i
    }
  }

  subscript(index: String) -> Int { return self.int(index) }
  subscript(index: String) -> String { return self.string(index) }
  subscript(index: String) -> Bool { return self.bool(index) }

  func int(_ index: String) -> Int {
    return Int(values[labelToIndex[index]!])!
  }

  func string(_ index: String) -> String {
    return values[labelToIndex[index]!]
  }

  func bool(_ index: String) -> Bool {
    return values[labelToIndex[index]!].lowercased() == "true"
  }
}


func readCSV<T>(url: URL, mapper: @escaping (StringBox) -> T) throws -> [T] {
  let string = try String(contentsOf: url)
  var results = [T]()
  var labels = [String]()

  var i = 0
  string.enumerateLines {
    (line: String, stop: inout Bool) in
    guard !line.isEmpty && !line.starts(with: "#") else { return }
    let values = line.split(separator: ",").map({ String($0) })
    guard values.count > 0 else { return }
    guard i > 0 else {
      labels = values
      i += 1
      return
    }
    results.append(mapper(StringBox(labels: labels, values: values)))
    i += 1
  }
  return results
}
