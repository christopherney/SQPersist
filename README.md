SQPersist
=========

Objective-C Persistence framework wrapper around SQLite.

```!!! Development in progress !!!```

What is it?
---------------

**SQPersist** is a Objective-C Persistence framework wrapper around **SQLite** based on FMDB (https://github.com/ccgus/fmdb).

With **SQPersist** you can store your custom objects in **SQLite** database without create a database and without used Core Data Framework.

Language
---------------

SQPersist is written in Objective-C with Automatic Reference Counting (ARC) system.

How it's work ?
---------------

Add a model object into the storage
---------------

Simply inherits your object with the class named **SQPObject**.

At the first initialization of your object, the **SQPersist** will check if the associate table exists in the database. If not, the table will be create automaticatly.
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
The table will be create at the first initialization of your object (if the table not already exists) :
```
Car *car1 = [[Car alloc] init];
```

Manipulate the objects
---------------

INSERT an object
---------------
To insert a new object into your database, just call the method named ***SQPSaveEntity*** :
```
// Create Table at the first init (if tbale ne exists) :
User *userCreated = [[User alloc] init];
userCreated.firstName = @"Christopher";
userCreated.lastName = @"Ney";
    
// INSERT Object :
[userCreated SQPSaveEntity];
```

UPDATE an object
---------------
To update an existing object into your database, just call the method named ***SQPSaveEntity*** :
```
// SELECT BY objectID :
User *existingUser = (User*)[User SQPFetchOneByID:objectID];
existingUser.amount = 10.50f;
    
// UPDATE Object :
[existingUser SQPSaveEntity];
```

DELETE an object
---------------
To dlete an existing object of your database, set the property ***deleteObject*** to ***YES*** and call the method named ***SQPSaveEntity*** :

```
// DELETE Object :
existingUser.deleteObject = YES;
[existingUser SQPSaveEntity];
```

Other methods
---------------

```
// REMOVE Local Database :
[[SQPDatabase sharedInstance] removeDatabase];
    

    
// SELECT BY objectID :
User *userSelected = (User*)[User SQPFetchOneByID:userCreated.objectID];
userSelected.amount = 10.50f;
    
// UPDATE Object :
[userSelected SQPSaveEntity];
    
Car *car1 = [[Car alloc] init];
car1.name = @"Ferrari";
car1.color = @"Red";
[car1 SQPSaveEntity]; // INSERT Object
    
Car *car2 = [[Car alloc] init];
car2.name = @"BMW";
car2.color = @"Black";
[car2 SQPSaveEntity]; // INSERT Object
 
Car *car3 = [[Car alloc] init];
car3.name = @"Ferrari";
car3.color = @"Yellow";
[car3 SQPSaveEntity]; // INSERT Object
  
// DELETE Object :
car3.deleteObject = YES;
[car3 SQPSaveEntity];

// SELECT ALL 'Ferrari' :
NSMutableArray *cars = [Car SQPFetchAllWhere:@"name = 'Ferrari'"];

NSLog(@"Number of cars: %d", [cars count]);
```
License
----

MIT


**Free Library**
