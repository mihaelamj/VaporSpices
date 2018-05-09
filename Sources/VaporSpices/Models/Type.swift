//
//  Form.swift
//  App
//
//  Created by Mihaela Mihaljevic Jakic on 09/05/2018.
//

import Async
import Fluent
import Foundation

public final class Type<D>: Model where D: QuerySupporting, D: IndexSupporting {
  
  public typealias Database = D
  public typealias ID = Int
  public static var idKey: IDKey { return \.id }
  public static var entity: String {
    return "type"
  }
  public static var database: DatabaseIdentifier<D> {
    return .init("type")
  }
  
  var id: Int?
  var name: String
  var description: String
  
  init(name: String, description: String) {
    self.name = name
    self.description = description
  }
}

extension Type: Migration where D: QuerySupporting, D: IndexSupporting { }


//MARK: - Populating data

let typeNames : [[String: String]] = [
  ["name": "basic", "desc": "Basic spices like basil, Cumin, Horseradish."],
  ["name": "chilly", "desc": "Chilly family."],
  ["name": "fish", "desc": "Spices from fermented fish."],
  ["name": "mix-green", "desc": "Green spice mixes, Italian, French."],
  ["name": "mix-yellow", "desc": "Turmeric based spice mixes."],
  ["name": "onion", "desc": "Onion family."],
  ["name": "produce", "desc": "Spices made from died produce, like Spinach powder."],
  ["name": "salt", "desc": "Salt family."],
  ["name": "savoury", "desc": "Savoury spices like mushrooms, algae."],
  ["name": "sweet", "desc": "Sweet spices like Vanilla."],
  ["name": "thickener", "desc": "Spices that thicken the dish like Psyllium, Agar Agar."]
]

public struct TypeMigration<D>: Migration where D: QuerySupporting & SchemaSupporting & IndexSupporting {
  public typealias Database = D
  
  static func prepareFields(on connection: Database.Connection) -> Future<Void> {
    return Database.create(Type<Database>.self, on: connection) { builder in
      
      //add fields
      try builder.field(for: \Type<Database>.id)
      try builder.field(for: \Type<Database>.name)
      try builder.field(for: \Type<Database>.description)
      
      //indexes
      try builder.addIndex(to: \.name, isUnique: true)
    }
  }
  
  static func prepareInsertData(on connection: Database.Connection) ->  Future<Void>   {
    let futures : [EventLoopFuture<Void>] = typeNames.map { type in
      let name = type["name"]!
      let desc = type["desc"]!
      return Type<D>(name: name, description: desc).create(on: connection).map(to: Void.self) { _ in return }
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
      let futures = try typeNames.map { type -> EventLoopFuture<Void> in
        let name = type["name"]!
        return try Type<D>.query(on: connection).filter(\Type.name, .equals, .data(name)).delete()
      }
      return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }
    catch {
      return connection.eventLoop.newFailedFuture(error: error)
    }
  }
}

