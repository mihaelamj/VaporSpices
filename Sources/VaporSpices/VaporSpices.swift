import Foundation
import Fluent

public extension MigrationConfig {
  public mutating func addVaporSpices<D>(for database: DatabaseIdentifier<D>) where D: QuerySupporting & SchemaSupporting & IndexSupporting & ReferenceSupporting {
    
    Form<D>.defaultDatabase = database
    self.add(migration: FormMigration<D>.self, database: database)
    
    Heat<D>.defaultDatabase = database
    self.add(migration: HeatMigration<D>.self, database: database)
    
    Technique<D>.defaultDatabase = database
    self.add(migration: TechniqueMigration<D>.self, database: database)
    
    Season<D>.defaultDatabase = database
    self.add(migration: SeasonMigration<D>.self, database: database)
    
    Volume<D>.defaultDatabase = database
    self.add(migration: VolumeMigration<D>.self, database: database)
    
    Weight<D>.defaultDatabase = database
    self.add(migration: WeightMigration<D>.self, database: database)
    
    Type<D>.defaultDatabase = database
    self.add(migration: TypeMigration<D>.self, database: database)
    
    Function<D>.defaultDatabase = database
    self.add(migration: FunctionMigration<D>.self, database: database)
    
    Heat<D>.defaultDatabase = database
    self.add(migration: HeatMigration<D>.self, database: database)
    
    Taste<D>.defaultDatabase = database
    self.add(migration: TasteMigration<D>.self, database: database)
  }
}
