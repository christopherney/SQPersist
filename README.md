SQPersist
=========

Objective-C Persistence framework wrapper around SQLite.

```Version 1.0.1```

What is it?
-----------

**SQPersist** is a Objective-C Persistence framework wrapper around **SQLite** based on FMDB (https://github.com/ccgus/fmdb).

With **SQPersist** you can store your custom objects in **SQLite** database without creating manually your database and using Core Data Framework.

Language
--------

SQPersist is written in Objective-C with Automatic Reference Counting (ARC) system.

CocoaPods
---------
**SQPersist** can be installed using [CocoaPods](http://cocoapods.org/).

[![Dependency Status](https://www.versioneye.com/objective-c/SQPersist/1.0.0/badge.svg?style=flat)](https://www.versioneye.com/objective-c/SQPersist/1.0.0)
[![Reference Status](https://www.versioneye.com/objective-c/SQPersist/reference_badge.svg?style=flat)](https://www.versioneye.com/objective-c/SQPersist/references)


```
pod 'SQPersist'
```

How it's work ?
---------------

Setup your local storage
------------------------
To setup (create the SQLite file), use the following method :
the table will be created automaticatly.
```
[[SQPDatabase sharedInstance] setupDatabaseWithName:@"myDbName.db"];
```
> If your start to use the entities without setup the database name, the database name will be ***SQPersist.db*** by default.

Add a model object into the storage
-----------------------------------

Simply inherits your object with the class named **SQPObject**.

The **SQPersist** will check if the associating table exists into the database during the first initialization of your object. If not, the table will be created automaticatly.
```
#import <Foundation/Foundation.h>
#import "SQPObject.h"

@interface Car : SQPObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *color;
@property (nonatomic) int power;

@end
```

The resulting table into the SQLite database will be :
```
+---------------------------------+
|SQPCar                           |
+----------+------+-------+-------+
| objectID | name | color | power |
+----------+------+-------+-------+
| -------- | ---- | ----- | ----- |
+----------+------+-------+-------+
| -------- | ---- | ----- | ----- |
+----------+------+-------+-------+
```
The table will be created during the first initialization of your object (if the table not already exists) :
```
Car *car1 = [Car SQPCreateEntity];
```

All objects are identified by an unique identifier named ***objectID***. The ***objectID*** is a UUID (NSString).
```
NSLog(@"Object identifier : %@", car1.objectID);
```

Compatibility with Objective-C Types
-----------------------------
SQPersist is compatible with the following Objective-C types :
* ***NSString*** -> become ***TEXT*** into SQLite database
* ***NSNumber*** -> become ***REAL*** into SQLite database
* ***NSDecimalNumber*** -> become ***REAL*** into SQLite database
* ***NSDate*** -> become ***INTEGER*** into SQLite database (Timestamp Since 1970)
* ***NSData*** -> become ***BLOB*** into SQLite database
* ***UIImage*** -> become ***BLOB*** into SQLite database
* ***NSURL*** -> become ***TEXT*** into SQLite database
* ***int*** -> become ***INTEGER*** into SQLite database
* ***double*** -> become ***REAL*** into SQLite database
* ***long*** -> become ***REAL*** into SQLite database
* ***long long*** -> become ***REAL*** into SQLite database
* ***short*** -> become ***INTEGER*** into SQLite database
* ***float*** -> become ***REAL*** into SQLite database
 
Each property of entities objects are analysed with Objective-C methods : ***property_getAttributes()***.

***Apple documentation :***
> https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

Children entities
-----------------
If your object contains some properties of ***SQPObject*** type, or ***NSArray*** of SQPObject. The children objects will be save too, when you call the method ***SQPSaveEntity*** of the main object.

Manipulate the objects
----------------------

INSERT an object
----------------
To insert a new object into your database, just call the method named ***SQPSaveEntity*** :
```
// Create Table at the first init (if the table not exists) :
User *userCreated = [User SQPCreateEntity];
userCreated.firstName = @"John";
userCreated.lastName = @"McClane";
    
// INSERT Object :
[userCreated SQPSaveEntity];
```

UPDATE an object
----------------
To update an existing object into your database, just call the method named ***SQPSaveEntity*** :
```
// SELECT BY objectID :
User *existingUser = [User SQPFetchOneByID:objectID];
existingUser.amount = 10.50f;
    
// UPDATE Object :
[existingUser SQPSaveEntity];
```

DELETE an object
----------------
To delete an existing object of your database, set the property ***deleteObject*** to ***YES*** and call the method named ***SQPSaveEntity***. Or diretcly call the method named ***SQPDeleteEntity***.

```
// DELETE Object :
existingUser.deleteObject = YES;
[existingUser SQPSaveEntity]; // Commit the delete command.
```
```
// DELETE Object :
[existingUser SQPDeleteEntity]; // Commit the delete command.
```

SELECT One object
--------------------
To select one objet you can use 3 methods ***SQPFetchOneByID*** or ***SQPFetchOneWhere:*** or ***SQPFetchOneByAttribut:withValue:***.
```
// SELECT BY objectID :
User *userSelected = [User SQPFetchOneByID:userCreated.objectID];
```

```
// SELECT by condition :
User *userSelected = [User SQPFetchOneWhere:@"lastName = 'McClane'"];
```

```
// SELECT by attribute with value :
User *userSelected = [User SQPFetchOneByAttribut:@"lastName" withValue:@"McClane"];
```

SELECT collection of objects
------------------------
To select a collection of objets you can use 4 methods ***SQPFetchAll***, ***SQPFetchAllWhere:***,  ***SQPFetchAllWhere:orderBy:*** and ***SQPFetchAllWhere:orderBy:pageIndex:itemsPerPage:*** :
```
// SELECT ALL 'Cars' :
NSMutableArray *allCars = [Car SQPFetchAll];
```

```
// SELECT ALL 'Ferrari cars' :
NSMutableArray *ferrariCars = [Car SQPFetchAllWhere:@"name = 'Ferrari'"];
```

```
// SELECT ALL 'Ferrari cars' ordering by 'power' :
NSMutableArray *ferrariCars = [Car SQPFetchAllWhere:@"name = 'Ferrari' orderBy:@"power DESC"];
```
```
// SELECT ALL 'Ferrari cars' ordering by 'power' (first page - with 20 items per page) :
NSMutableArray *ferrariCars = [Car SQPFetchAllWhere:@"name = 'Ferrari' orderBy:@"power DESC" pageIndex:0 itemsPerPage:20];
```

COUNT Entities
--------------
To count the number of entities you can use 2 methods ***SQPCountAll*** or ***SQPCountAllWhere:***.
```
NSLog(@"Total cars : %lld", [Car SQPCountAll]);
NSLog(@"Total cars 'Ferrari' : %lld", [Car SQPCountAllWhere:@"name = 'Ferrari'"]);
```

TRUNCATE Entities
-----------------
To remove every entities (truncate), use the method ***SQPTruncateAll***.
```
[Car SQPTruncateAll];
```

Other methods
-------------
You can remove the database with the method ***removeDatabase*** :
```
// REMOVE Local Database :
[[SQPDatabase sharedInstance] removeDatabase];
```
Test if database file exists on local :
```
if ([[SQPDatabase sharedInstance] databaseExists]) {
    // SQLite Db file exists.
}
```
Add new property into an existing table (use just for update your model - generate many SQL request) :
```
[SQPDatabase sharedInstance].addMissingColumns == YES;
```

Tips
----
When you change the structure of your object :
* Clean your Xcode project before rebuild the solution.
* Remove the older database with the method ***removeDatabase*** (before changes).

License
----

MIT

**Free Library**
