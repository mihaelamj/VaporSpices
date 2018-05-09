# VaporSpices

Vapor 3 Package for pre-populating any database with Spice related data.

Import it into your project:
```
let package = Package(name: "TestVaporCountries",
dependencies: [      
//VaporSpices
  .package(url: "https://github.com/mihaelamj/VaporSpices", from: "0.1.0")
],
targets: [
  .target(name: "App", dependencies: ["FluentSQLite", "FluentMySQL", "FluentPostgreSQL", "VaporSpices"]),
]
)

Usage (for MySQL) :

```swift
import VaporSpices

migrations.addVaporSpices(for: .mysql)
  ```

 Usage (for PostgreSQL) : 

```swift
import VaporSpices

migrations.addVaporSpices(for: .psql)
  ```
 Usage (for SQLite) : 
 ```swift
import VaporSpices

migrations.addVaporSpices(for: .sqlite)
 ```
