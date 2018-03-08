//
//  LoadScene.swift
//  RogueKit
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


class LoadScene: Scene {
  let worldModel: WorldModel
  let id: String
  let resources: ResourceCollectionProtocol

  var terminal: BLTerminalInterface? { return director?.terminal }

  init(worldModel: WorldModel, resources: ResourceCollectionProtocol, id: String) {
    self.worldModel = worldModel
    self.id = id
    self.resources = resources
  }

  var nextScene: Scene?

  override func update(terminal: BLTerminalInterface) {
    print("Loading map \(id) using generator \(worldModel.mapDefinitions[id]!.generatorId)")
    guard worldModel.maps[self.id] == nil else {
      worldModel.travel(to: self.id)
      self.director?.transition(to: LevelScene(resources: self.resources, worldModel: self.worldModel))
      return
    }

    let rng = worldModel.rngStore[id]
    let reader = GeneratorReader(resources: resources)
    try! reader.run(
      id: worldModel.mapDefinitions[id]!.generatorId,
      rng: rng,
      factory: { PurePrefabGenerator(
        rng: $0,
        resources: $1,
        size: $2,
        mapDefinition: self.worldModel.mapDefinitions[self.id]!) })
    {
      gen, status, result in
      print(status)

      guard self.director?.activeScene === self else { return }

      terminal.clear()
      terminal.layer = 0
      gen.draw(in: terminal, at: BLPoint.zero)
      terminal.layer = 2
      gen.debugDistanceField?.draw(in: terminal, at: BLPoint.zero)
      terminal.refresh()

      if result != nil {
        let levelMap = try LevelMap(
          definition: worldModel.mapDefinitions[self.id]!,
          size: gen.cells.size,
          paletteName: "default",
          resources: resources,
          terminal: terminal,
          generator: gen)

        var itemPoints = gen.points(where: {
          $0.poi?.kind == .item || $0.poi?.kind == .weapon || $0.poi?.kind == .armor
        })
        rng.shuffleInPlace(&itemPoints)

        var reqdMobPoints = gen.points(where: { $0.poi?.kind == .mob && $0.poi?.isRequired == true })
        rng.shuffleInPlace(&reqdMobPoints)
        var nonReqdMobPoints = gen.points(where: { $0.poi?.kind == .mob && $0.poi?.isRequired == false })
        rng.shuffleInPlace(&nonReqdMobPoints)
        // drop 'required' mobs first
        var mobPoints = reqdMobPoints + nonReqdMobPoints

        var entrancePoints = gen.points(where: { $0.poi?.kind == .entrance && $0.poi?.isRequired == true })
        if entrancePoints.isEmpty {
          entrancePoints = gen.points(where: { $0.poi?.kind == .entrance })
        }
        rng.shuffleInPlace(&entrancePoints)

        var exitPoints = gen.points(where: { $0.poi?.kind == .exit && $0.poi?.isRequired == true })
        if exitPoints.isEmpty {
          exitPoints = gen.points(where: { $0.poi?.kind == .exit })
        }
        rng.shuffleInPlace(&exitPoints)

        if entrancePoints.isEmpty {
          print("ERROR: no entrance points in this map!")
          entrancePoints = [mobPoints.removeFirst()]
        }
        if exitPoints.isEmpty {
          print("ERROR: no exit points in this map!")
          exitPoints = [mobPoints.removeFirst()]
        }

        let playerStart: BLPoint = entrancePoints.removeFirst()
        levelMap.pointsOfInterest = [
          PointOfInterest(kind: "playerStart", point: playerStart),
        ]
        if levelMap.definition.exits["previous"] != nil {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "entrance", point: playerStart))
        }
        if levelMap.definition.exits["next"] != nil {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "exit", point: exitPoints.removeFirst()))
        }

        var i = 0
        while i < levelMap.definition.numItems && !itemPoints.isEmpty {
          let p = itemPoints.removeFirst()
          let genCell = gen.cells[p]
          guard let poi = genCell.poi else {
            fatalError("How did we even get here?")
          }

          let weapons = worldModel.csvDB.weapons(matching: poi.tags)
            .filter({ $0.matches(levelMap.definition.tagWhitelist) })
            .map({ WeightedChoice.Choice(value: $0.id, weight: $0.weight) })
          let armors = worldModel.csvDB.armors(matching: poi.tags)
            .filter({ $0.matches(levelMap.definition.tagWhitelist) })
            .map({ WeightedChoice.Choice(value: $0.id, weight: $0.weight) })

          if poi.kind == .weapon {
            guard !weapons.isEmpty else { continue }
            let weapon = WeightedChoice(choices: weapons).choose(rng: rng)
            levelMap.pointsOfInterest.append(PointOfInterest(kind: "weapon:#\(weapon)", point: p))
            i += 1
          } else if poi.kind == .armor {
            guard !armors.isEmpty else { continue }
            let armor = WeightedChoice(choices: armors).choose(rng: rng)
            levelMap.pointsOfInterest.append(PointOfInterest(kind: "armor:#\(armor)", point: p))
            i += 1
          } else if poi.kind == .item {
            let allItems = weapons + armors
            guard !allItems.isEmpty else { continue }
            let item = WeightedChoice(choices: allItems).choose(rng: rng)
            levelMap.pointsOfInterest.append(PointOfInterest(kind: "item:\(item)", point: p))
            i += 1
          } else {
            fatalError("Should not be possible due to earlier filtering")
          }
        }

        i = 0
        while i < levelMap.definition.numMobs && !mobPoints.isEmpty {
          let p = mobPoints.removeFirst()
          let genCell = gen.cells[p]
          guard let poi = genCell.poi else {
            fatalError("How did we even get here?")
          }

          let mobsFirstPass = worldModel.csvDB.actors(matching: poi.tags)
          let mobsSecondPass = mobsFirstPass.filter({
            let m = $0
            return m.matches(levelMap.definition.tagWhitelist)
          })
          let mobs = mobsSecondPass
            .map({ WeightedChoice.Choice(value: $0.id, weight: $0.weight) })
          guard !mobs.isEmpty else {
            print("No mobs match", poi.tags, "and", levelMap.definition.tagWhitelist)
            continue
          }
          let mob = WeightedChoice(choices: mobs).choose(rng: rng)
          print("Instantiating", mob)
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "enemy:#\(mob)", point: p))
          i += 1
        }

        /*
        var floorsWithMargins = Array(levelMap.floorsWithMargins)
        rng.shuffleInPlace(&floorsWithMargins)
        let entrance = floorsWithMargins[0]
        let exit = floorsWithMargins[1]
        let playerStart = rng.choice(Array(floorsWithMargins[0]
          .getNeighbors(bounds: BLRect(size: levelMap.size), diagonals: false)))

        let blacklist = [entrance, exit]
        var floors = levelMap.floors.filter({ !blacklist.contains($0) })
        rng.shuffleInPlace(&floors)
        var floorIndex = 0
        let getFloor: () -> BLPoint = {
          let val = floors[floorIndex]
          floorIndex += 1
          return val
        }
        
        levelMap.pointsOfInterest = [
          PointOfInterest(kind: "playerStart", point: playerStart),
        ]
        if levelMap.definition.exits["previous"] != nil {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "entrance", point: entrance))
        }
        if levelMap.definition.exits["next"] != nil {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "exit", point: exit))
        }
        for _ in 0..<10 {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "enemy:early", point: getFloor()))
        }
        for _ in 0..<10 {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "weapon:basic", point: getFloor()))
        }
        for _ in 0..<10 {
          levelMap.pointsOfInterest.append(PointOfInterest(kind: "armor:basic", point: getFloor()))
        }
        */

        levelMap.isPopulated = true

        self.worldModel.maps[self.id] = levelMap
        self.worldModel.travel(to: self.id)
        self.worldModel.applyPOIs()
        self.director?.transition(to: LevelScene(resources: self.resources, worldModel: self.worldModel))
      }
    }
  }
}
