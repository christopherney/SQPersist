SQPersist
=========

Objective-C Persistence framework wrapper around SQLite.

    !!! Development in progress !!!

How it's work ?
---------------

**SQPersist** is a Objective-C Persistence framework wrapper around **SQLite** based on FMDB (https://github.com/ccgus/fmdb).

With **SQPersist** you can store your custom objects in **SQLite** database without create a database and without used Core Data Framework.

Language
---------------

SQPersist is written in Objective-C with Automatic Reference Counting (ARC) system.

Add an model object into my storage ?
---------------

Simply inherit your object with the class named **SQPObject**.

At the first initialization of your object, the **SQPersist** will check if the associate table exists in the database. If not, the table will be create automaticatly.


