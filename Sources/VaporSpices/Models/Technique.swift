//
//  Form.swift
//  App
//
//  Created by Mihaela Mihaljevic Jakic on 09/05/2018.
//

import Async
import Fluent
import Foundation

public final class Technique<D>: Model where D: QuerySupporting, D: IndexSupporting {
  
  public typealias Database = D
  
  public typealias ID = Int
  
  public static var idKey: IDKey { return \.id }
  
  public static var entity: String {
    return "technique"
  }
  
  public static var database: DatabaseIdentifier<D> {
    return .init("technique")
  }
  
  var id : Int?
  let name : String
  var description: String
  var heatID: Heat<Database>.ID
  
  init(name: String, description: String, heatID: Heat<Database>.ID) {
    self.name = name
    self.description = description
    self.heatID = heatID
  }
}

extension Technique: Migration where D: QuerySupporting, D: IndexSupporting, D: ReferenceSupporting { }

// MARK: - Relations

//Technique ⇇↦ Heat
extension Technique {
  /// A relation to this technique's heat.
  var heat: Parent<Technique, Heat<Database>>? {
    return parent(\.heatID)
  }
}

//MARK: - Populating data

let techniques  = [
  "moist" : [
    (name: "sweat", desc: "To cook in fat without browning."),
    (name: "braise", desc: "To cook in a small amount of liquid, after browning. The exception would be some vegetables without first browning."),
    (name: "steam", desc: "To cook foods by exposing directly to steam."),
    (name: "blanch", desc: "To cook an item briefly, most commonly in water, but sometimes by other liquids (i.e., French fries in fat)."),
    (name: "poach", desc: "To cook in a small amount of liquid that is hot but not actually bubbling. Approximately 160º F to 165º F (71º C to 67ºC)."),
    (name: "simmer", desc: "To cook a liquid to a very gentle bubbling. Approximately 185º F to 205º F (85º C to 96º C)."),
    (name: "boil", desc: "To cook a liquid to bubbling or agitating rapidly. Water, at sea level, boils at 212º F(100º C)."),
    (name: "stew", desc: "To simmer food in a small amount of liquid that is in turn, served with food as a sauce."),
    (name: "deglaze", desc: "Adding and swirling liquid in pan to loosen food particles that remain on pan."),
    (name: "reduce", desc: "To cook by simmering or boiling to decrease the quantity of liquid and concentrating flavor.")
  ],
  "dry" : [
    (name: "deep-fry", desc: "To cook food submerged in hot fat"),
    (name: "pan-fry", desc: "To cook over moderate heat in a moderate amount of fat."),
    (name: "pan-broil", desc: "An underneath cooking method using uncovered pan without fat."),
    (name: "griddle", desc: "An underneath cooking method on a solid cooking surface with small amounts of fat."),
    (name: "sear", desc: "To brown a food’s surface quickly at high temperature."),
    (name: "bake", desc: "Similar to roasting but usually pertains to vegetables, fish, bread, and pastries."),
    (name: "broil", desc: "To cook by means of radiant heat from above."),
    (name: "grill", desc: "An underneath cooking method on an open grid."),
    (name: "saute", desc: "To cook quickly with high heat in a small amount of fat"),
    (name: "roast", desc: "To cook foods by surrounding them by, hot, dry air.")
  ],
  "raw" : [
    (name: "raw", desc: "To consume raw.")
  ]
]

public struct TechniqueMigration<D>: Migration where D: QuerySupporting & SchemaSupporting & IndexSupporting & ReferenceSupporting {
  
  public typealias Database = D
  
  //MARK: - Create Fields, Indexes and relations
  
  static func prepareFields(on connection: Database.Connection) -> Future<Void> {
    return Database.create(Technique<Database>.self, on: connection) { builder in
      
      //add fields
      try builder.field(for: \Technique<Database>.id)
      try builder.field(for: \Technique<Database>.name)
      try builder.field(for: \Technique<Database>.description)
      try builder.field(for: \Technique<Database>.heatID)
      
      //indexes
      try builder.addIndex(to: \.name, isUnique: true)
      
      //referential integrity - foreign key to parent
      try builder.addReference(from: \Technique<D>.heatID, to: \Heat<D>.id, actions: .init(update: .update, delete: .nullify))
    }
  }
  
  //MARK: - Helpers
  
  static func getHeatID(on connection: Database.Connection, heatName: String) -> Future<Heat<Database>.ID>  {
    do {
      // First look up the heat by its name
      return try Heat<D>.query(on: connection)
        .filter(\Heat.name == heatName)
        .first()
        .map(to: Heat<Database>.ID.self) { heat in
          guard let heat = heat else {
            throw FluentError(
              identifier: "PopulateTechniques_noSuchHeat",
              reason: "No heat named \(heatName) exists!",
              source: .capture()
            )
          }
          // Once we have found the heat, return it's id
          return heat.id!
      }
    }
    catch {
      return connection.eventLoop.newFailedFuture(error: error)
    }
  }
  
  static func addTechniques(on connection: Database.Connection, toHeatWithName heatName: String, heatTechniques: [(name: String, desc: String)]) -> Future<Void> {

    return getHeatID(on: connection, heatName: heatName)
      .flatMap(to: Void.self) { heatID in
        // Add each technique to the heat
        let futures = heatTechniques.map { touple -> EventLoopFuture<Void> in
          // Insert the Technique
          let name = touple.0
          let desc = touple.1
          return Technique<Database>(name: name, description: desc, heatID: heatID)
            .create(on: connection)
            .map(to: Void.self) { _ in return }
        }
        return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }
  }
  
  static func deleteTechniques(on connection: Database.Connection, forHeatWithName heatName: String, heatTechniques: [(name: String, desc: String)]) -> Future<Void> {
    return getHeatID(on: connection, heatName: heatName)
      .flatMap(to: Void.self) { heatID in
        // Delete each technique from the heat
        let futures = try heatTechniques.map { touple -> EventLoopFuture<Void> in
          // DELETE the technique if it exists
          let name = touple.0
          return try Technique<D>.query(on: connection)
            .filter(\Technique.heatID, .equals, .data(heatID))
            .filter(\Technique.name, .equals, .data(name))
            .delete()
        }
        return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }
  }
  
  static func prepareAddTechniques(on connection: Database.Connection) -> Future<Void> {
    let futures = techniques.map { heatName, techTouples in
      return addTechniques(on: connection, toHeatWithName: heatName, heatTechniques: techTouples)
    }
    return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
  }
  
  //MARK: - Required
  
  public static func prepare(on connection: Database.Connection) -> Future<Void> {
    let futureCreateFields = prepareFields(on: connection)
    let futureInsertData = prepareAddTechniques(on: connection)
    
    let allFutures : [EventLoopFuture<Void>] = [futureCreateFields, futureInsertData]
    
    return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
  }
  
  public static func revert(on connection: D.Connection) -> EventLoopFuture<Void> {
    let futures = techniques.map { heatName, techTouples in
      return deleteTechniques(on: connection, forHeatWithName: heatName, heatTechniques: techTouples)
    }
    return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
  }
  
}
