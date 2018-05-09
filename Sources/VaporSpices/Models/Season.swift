//
//  Form.swift
//  App
//
//  Created by Mihaela Mihaljevic Jakic on 09/05/2018.
//

import Async
import Fluent
import Foundation

public final class Season<D>: Model where D: QuerySupporting, D: IndexSupporting {
  
  public typealias Database = D
  public typealias ID = Int
  public static var idKey: IDKey { return \.id }
  public static var entity: String {
    return "season"
  }
  public static var database: DatabaseIdentifier<D> {
    return .init("season")
  }
  
  var id: Int?
  var name: String
  
  init(name: String) {
    self.name = name
  }
}

//Conform to Migration
extension Season: Migration where D: QuerySupporting, D: IndexSupporting { }

//MARK: - Populating data

let names = [
  "summer",
  "autumn",
  "winter",
  "spring"
]

public struct SeasonMigration<D>: Migration where D: QuerySupporting & SchemaSupporting & IndexSupporting {
  public typealias Database = D
  
  static func prepareFields(on connection: Database.Connection) -> Future<Void> {
    return Database.create(Season<Database>.self, on: connection) { builder in
      
      //add fields
      try builder.field(for: \Season<Database>.id)
      try builder.field(for: \Season<Database>.name)
      
      //indexes
      try builder.addIndex(to: \.name, isUnique: true)
    }
  }
  
  static func prepareInsertData(on connection: Database.Connection) ->  Future<Void>   {
    let futures : [EventLoopFuture<Void>] = names.map { name in
      return Season<D>(name: name).create(on: connection).map(to: Void.self) { _ in return }
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
      let futures = try names.map { name -> EventLoopFuture<Void> in
        return try Season<D>.query(on: connection).filter(\Season.name, .equals, .data(name)).delete()
      }
      return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }
    catch {
      return connection.eventLoop.newFailedFuture(error: error)
    }
  }
}

