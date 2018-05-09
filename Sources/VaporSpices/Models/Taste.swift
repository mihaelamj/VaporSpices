//
//  Form.swift
//  App
//
//  Created by Mihaela Mihaljevic Jakic on 09/05/2018.
//
import Async
import Fluent
import Foundation

public final class Taste<D>: Model where D: QuerySupporting, D: IndexSupporting {
  
  public typealias Database = D
  public typealias ID = Int
  public static var idKey: IDKey { return \.id }
  public static var entity: String {
    return "taste"
  }
  public static var database: DatabaseIdentifier<D> {
    return .init("taste")
  }
  
  var id: Int?
  let name : String
  var description: String
  let actions : String
  let sources : String
  
  init(name: String, description: String, actions: String, sources: String) {
    self.name = name
    self.description = description
    self.actions = actions
    self.sources = sources
  }
}

extension Taste: Migration where D: QuerySupporting, D: IndexSupporting { }


//MARK: - Populating data

let tastes : [(String, String, String, String)] = [
  
  ("sweet",
   "Sweet taste as in honey, mango.",
   "Builds tissues, calms nerves.",
   "Fruit, grains, natural sugars, milk."),
  
  ("salty",
   "Salty as anchovies.",
   "Improves taste to food, lubricates tissues, stimulates digestion.",
   "Natural salts, sea vegetables."),
  
  ("sour",
   "The sour taste comes from higher acidic foods such as citrus, which includes lemons or limes. The sour taste is caused by a hydrogen atom, or ions. The more atoms present in a food, the more sour it will taste.",
   "Cleanses tissues, increases absorption of minerals.",
   "Sour fruits, yogurt, fermented foods."),
  
  ("bitter",
   "Bitterness can be described as a sharp, pungent, or disagreeable flavor. Bitterness is neither salty nor sour, but may at times accompany these flavor sensations.",
   "Detoxifies and lightens tissues.",
   "Dark leafy greens, herbs and spices."),
  
  ("umami",
   "Savory, and characteristic of broths and cooked meats. The sensation of umami is due to the detection of the carboxylate anion of glutamate in specialized receptor cells present on the human and other animal tongues. (The taste of monosodium glutamate, commonly found in Chinese takeaways)",
   "Satiating.",
   "Fish, shellfish, cured meats, mushrooms, vegetables (e.g., ripe tomatoes, Chinese cabbage, spinach, celery, etc.) or green tea, and fermented and aged products involving bacterial or yeast cultures, such as cheeses, shrimp pastes, fish sauce, soy sauce, nutritional yeast, and yeast extracts.")
]

public struct TasteMigration<D>: Migration where D: QuerySupporting & SchemaSupporting & IndexSupporting {
  public typealias Database = D
  
  static func prepareFields(on connection: Database.Connection) -> Future<Void> {
    return Database.create(Taste<Database>.self, on: connection) { builder in
      
      //add fields
      try builder.field(for: \Taste<Database>.id)
      try builder.field(for: \Taste<Database>.name)
      try builder.field(for: \Taste<Database>.description)
      try builder.field(for: \Taste<Database>.actions)
      try builder.field(for: \Taste<Database>.sources)
      
      //indexes
      try builder.addIndex(to: \.name, isUnique: true)
    }
  }
  
  static func prepareInsertData(on connection: Database.Connection) ->  Future<Void>   {
    let futures : [EventLoopFuture<Void>] = tastes.map { name, desc, action, sources in
      return Taste<D>(name: name, description: desc, actions: action, sources: sources).create(on: connection).map(to: Void.self) { _ in return }
    }
    return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
  }
  
  public static func prepare(on connection: Database.Connection) -> Future<Void> {
    
    let futureCreateFields = prepareFields(on: connection)
    let futureInsertData = prepareInsertData(on: connection)
    
    let allFutures : [EventLoopFuture<Void>] = [futureCreateFields, futureInsertData]
    
    return Future<Void>.andAll(allFutures, eventLoop: connection.eventLoop)
  }
  
  public static func revert(on connection: Database.Connection) -> Future<Void> {
    do {
      // Delete all names
      let futures = try tastes.map { touple -> EventLoopFuture<Void> in
        let name = touple.0
        return try Taste<D>.query(on: connection).filter(\Taste.name, .equals, .data(name)).delete()
      }
      return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }
    catch {
      return connection.eventLoop.newFailedFuture(error: error)
    }
  }
}
