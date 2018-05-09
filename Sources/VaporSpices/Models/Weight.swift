//
//  Form.swift
//  App
//
//  Created by Mihaela Mihaljevic Jakic on 09/05/2018.
//

import Async
import Fluent
import Foundation

public final class Weight<D>: Model where D: QuerySupporting, D: IndexSupporting {
  
  public typealias Database = D
  public typealias ID = Int
  public static var idKey: IDKey { return \.id }
  public static var entity: String {
    return "weight"
  }
  public static var database: DatabaseIdentifier<D> {
    return .init("weight")
  }
  
  var id: Int?
  var name: String
  
  init(name: String) {
    self.name = name
  }
}

//Conform to Migration
extension Weight: Migration where D: QuerySupporting, D: IndexSupporting { }

//MARK: - Populating data

let weightNames = [
  "delicate",
  "light",
  "light-medium",
  "medium",
  "moderate-heavy",
  "medium-heavy",
  "heavy",
  "very-heavy"
]

public struct WeightMigration<D>: Migration where D: QuerySupporting & SchemaSupporting & IndexSupporting {
  public typealias Database = D
  
  static func prepareFields(on connection: Database.Connection) -> Future<Void> {
    return Database.create(Weight<Database>.self, on: connection) { builder in
      
      //add fields
      try builder.field(for: \Weight<Database>.id)
      try builder.field(for: \Weight<Database>.name)
      
      //indexes
      try builder.addIndex(to: \.name, isUnique: true)
    }
  }
  
  static func prepareInsertData(on connection: Database.Connection) ->  Future<Void>   {
    let futures : [EventLoopFuture<Void>] = weightNames.map { name in
      return Weight<D>(name: name).create(on: connection).map(to: Void.self) { _ in return }
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
      let futures = try weightNames.map { name -> EventLoopFuture<Void> in
        return try Weight<D>.query(on: connection).filter(\Weight.name, .equals, .data(name)).delete()
      }
      return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }
    catch {
      return connection.eventLoop.newFailedFuture(error: error)
    }
  }
}

