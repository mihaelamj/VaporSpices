//
//  Form.swift
//  App
//
//  Created by Mihaela Mihaljevic Jakic on 09/05/2018.
//
import Async
import Fluent
import Foundation

public final class Function<D>: Model where D: QuerySupporting, D: IndexSupporting {
  
  public typealias Database = D
  public typealias ID = Int
  public static var idKey: IDKey { return \.id }
  public static var entity: String {
    return "function"
  }
  public static var database: DatabaseIdentifier<D> {
    return .init("function")
  }
  
  var id: Int?
  var name: String
  var description: String
  
  init(name: String, description: String) {
    self.name = name
    self.description = description
  }
}

extension Function: Migration where D: QuerySupporting, D: IndexSupporting { }


//MARK: - Populating data

let functionNames : [[String: String]] = [
  ["name": "appetizer", "desc": "Hightens the appetite"],
  ["name": "thirst-quenching", "desc": "Quenches thirst"],
  ["name": "refreshing", "desc": "Refreshes"],
  ["name": "satiating", "desc": "Satiating"],
  ["name": "warming", "desc": "Warming sensation"],
  ["name": "cooling", "desc": "Cooling sensation"]
]

public struct FunctionMigration<D>: Migration where D: QuerySupporting & SchemaSupporting & IndexSupporting {
  public typealias Database = D
  
  static func prepareFields(on connection: Database.Connection) -> Future<Void> {
    return Database.create(Function<Database>.self, on: connection) { builder in
      
      //add fields
      try builder.field(for: \Function<Database>.id)
      try builder.field(for: \Function<Database>.name)
      try builder.field(for: \Function<Database>.description)
      
      //indexes
      try builder.addIndex(to: \.name, isUnique: true)
    }
  }
  
  static func prepareInsertData(on connection: Database.Connection) ->  Future<Void>   {
    let futures : [EventLoopFuture<Void>] = functionNames.map { item in
      let name = item["name"]!
      let desc = item["desc"]!
      return Function<D>(name: name, description: desc).create(on: connection).map(to: Void.self) { _ in return }
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
      let futures = try functionNames.map { item -> EventLoopFuture<Void> in
        let name = item["name"]!
        return try Function<D>.query(on: connection).filter(\Function.name, .equals, .data(name)).delete()
      }
      return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }
    catch {
      return connection.eventLoop.newFailedFuture(error: error)
    }
  }
}

