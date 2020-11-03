# SimpleStorage

Sqlite Storage to store data very simpel

- Store and read data very easily (`Int, Double, String, UUID, Bool, Date`)
- Referential integrity with `.relationship`-Attribute
- Automatically managed `created_at` and `updated_at` Attributes
- Typesafe with `SimpleStorageStorableType`
- Migrations

## Initialization
```
let simpleStorage = try SimpleStorage(configuration: .defaultInMemory)

let myType = SimpleStorageType(simpleStorage: simpleStorage, storageType: "my-type")

//Migration
if (try myType.storageTypeVersion == 0) {
    try storageType.addAttribute(attribute: Attribute(name: "my-string", type: .string))
    try storageType.addAttribute(attribute: Attribute(name: "my-uuid", type: .uuid, nullable: true))
    try storageType.addAttribute(attribute: Attribute(name: "my-date", type: .date))
    try storageType.addAttribute(attribute: Attribute(name: "my-bool", type: .bool))
    try storageType.addAttribute(attribute: Attribute(name: "my-integer", type: .integer))
    try storageType.addAttribute(attribute: Attribute(name: "my-double", type: .double))
    
    try storageType.setStorageTypeVersion(version: 1)
}

if (try myType.storageTypeVersion == 0) {
    try storageType.addAttribute(Attribute(name: "my-relationship", type: .relationship("other-type")))
}
```

## Data
You can use a generic `Item`-type or a typesafe `SimpleStorageStorableType`-Type

### Generic Item Type

```
//Initalize with existing id
Item(id: UUID, values: [String: StorableType])

//Infer id from values or create a new one
Item(values: [String: StorableType])
```
#### Write

```
let item = Item(
    values: [
        "my-string": ANY-STRING,
        "my-uuid": ANY-UUID,
        "my-date": ANY-DATE,
        "my-bool": ANY-BOOL,
        "my-integer": ANY-INTEGEr,
        "my-double": ANY-DOUBLE,
        "my-relationship": ANY-UUID,
    ]
)
```

#### Read 
```
let myString: String = item.value(name: "my-string")
let myUUID: UUID = item.value(name: "my-uuid")
let myDate: Date = item.value(name: "my-date")
let myBool: Bool = item.value(name: "my-bool")
let myInteger: Int = item.value(name: "my-integer")
let myDouble: Double = item.value(name: "my-double")
let myRelationship: UUID = item.value(name: "my-relationship")
```

### SimpleStorageStorableType

```
public protocol SimpleStorageStorableType {
    static func map(_ item: Item) throws -> Self
    static func map(_ storableType: Self) -> Item
}
```

```
struct MyType: Equatable {
    let myString: String
    let myUUID: UUID
    let myDate: Date
    let myBool: Bool
    let myInteger: Int
    let myDouble: Double
    let myRelationship: UUID
}

extension MyType {
    static func map(_ item: Item) throws -> MyType {
       return MyType(
           myString = item.value(name: "my-string")
           myUUID = item.value(name: "my-uuid")
           myDate = item.value(name: "my-date")
           myBool = item.value(name: "my-bool")
           myInteger = item.value(name: "my-integer")
           myDouble = item.value(name: "my-double")
           myRelationship  = item.value(name: "my-relationship")
       )
    }
    
    static func map(_ storableType: MyType) -> Item {
        return Item(
            values: [
                "my-string": myType.myString,
                "my-uuid": myType.myUUID,
                "my-date": myType.myDate,
                "my-bool": myType.myBool,
                "my-integer": myType.myInteger,
                "my-double": myType.myDouble,
                "my-relationship": myType.my,
            ]
        )   
    }
}
```

## Add new Types
### Generic Item
```
public func createOrUpdate(item: Item) throws
public func createOrUpdate(items: [Item]) throws
```

### Typesafe 
```
public func createOrUpdate<T: SimpleStorageStorableType>(storableType: T) throws
public func createOrUpdate<T: SimpleStorageStorableType>(storableType: [T]) throws
```

## Read Data
### Generic Item
```
public func find(id: UUID) throws -> Item?
public func find(expression: Expression = .empty) throws -> [Item]
```

### Typesafe 
```
public func find<T: SimpleStorageStorableType>(id: UUID) throws -> T?
public func find<T: SimpleStorageStorableType>(expression: Expression = .empty) throws -> [T]
```
