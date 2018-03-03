//
//  Assemblies.swift
//  RogueKitPackageDescription
//
//  Created by Steve Johnson on 3/2/18.
//

import Foundation
import BearLibTerminal


protocol EntityAssemblyProtocol {
  static func assemble(entity: Entity, worldModel: WorldModel)
}


//class EntranceAssembly: EntityAssemblyProtocol {
//  static func assemble(entity: Entity, worldModel: WorldModel) {
//    worldModel.spriteS.add(component: SpriteC(entity: entity, int: nil, str: "<"))
//  }
//}

