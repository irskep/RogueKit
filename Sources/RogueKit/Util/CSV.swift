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
  subscript(index: String) -> Double { return self.double(index) }
  subscript(index: String) -> String { return self.string(index) }
  subscript(index: String) -> Bool { return self.bool(index) }

  func isQuotes(_ index: String) -> Bool {
    return self.string(index) == "\"" || self.string(index) == "\"\""
  }

  func int(_ index: String) -> Int {
    let s = self.string(index)
    if s.isEmpty { return 0 }
    return Int(s) ?? 0
  }

  func double(_ index: String) -> Double {
    let s = self.string(index)
    if s.isEmpty { return 0 }
    return Double(s) ?? 0
  }

  func stringList(_ index: String) -> [String] {
    return self.string(index).split(separator: ",").map { $0.lowercased() }
  }

  func maybeString(_ index: String) -> String? {
    if self.string(index).isEmpty { return nil } else { return self.string(index) }
  }

  func string(_ index: String) -> String {
    guard let valueIndex = labelToIndex[index] else { fatalError("Index out of range") }
    if valueIndex >= values.count {
      return ""
    } else {
      return values[labelToIndex[index]!]
    }
  }

  func bool(_ index: String) -> Bool {
    let s = self.string(index)
    if s.isEmpty { return false }
    return s.lowercased() == "true"
  }
}


private let QUOTE: Character = "\""
func parseQuotedColumn(_ line: String, _ left: String.Index) -> (String, String.Index) {
  let left = line.index(after: left)  // skip initial quote
  var right = left

  var chars = [Character]()
  var numQuotes = 0
  while right < line.endIndex {
    switch line[right] {
    case "," where numQuotes == 1:
      let s = String(line[left..<line.index(before: right)])
      return (s, line.index(after: right))
    case QUOTE where numQuotes == 1:
      chars.append(QUOTE)
      numQuotes = 0
    case QUOTE:
      numQuotes += 1
    default:
      chars.append(line[right])
    }
    right = line.index(after: right)
  }

  guard numQuotes == 1 else {
    fatalError("Missing closing quote in: \(line)")
  }
  return (String(chars), right)
}


func parseLine(_ line: String) -> [String] {
  var values = [String]()

  var left = line.startIndex
  var right = left

  while true {
    guard left < line.endIndex else { break }
    if line[left] == QUOTE {
      let (value, newLeft) = parseQuotedColumn(line, left)
      values.append(value)
      left = newLeft
      right = left
      if right == line.endIndex { break }
      continue
    }

    if right == line.endIndex || line[right] == "," {
      values.append(String(line[left..<right]))

      if right == line.endIndex {
        break
      } else {
        left = line.index(after: right)
        right = left
      }
    } else {
      right = line.index(after: right)
    }
  }

  return values
}


func readCSV<T>(url: URL, mapper: @escaping (StringBox) -> T) throws -> [T] {
  let string = try String(contentsOf: url, encoding: .utf8)
  var results = [T]()
  var labels = [String]()

  var i = 0
  string.enumerateLines {
    (line: String, stop: inout Bool) in
    guard !line.isEmpty && !line.starts(with: "#") else { return }

    let values = parseLine(line)
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
