//
//  SQPDatabase.h
//  SQPersist
//
//  Created by Christopher Ney on 30/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@interface SQPDatabase : NSObject {
    
    FMDatabase *_database;
    NSString *_dbName;
    NSString *_dbPath;
}

/**
 *  Get the main instance of the database manager.
 *
 *  @return Instance.
 */
+ (id)sharedInstance;

/**
 *  Setup the database.
 *
 *  @param dbName Name of the database.
 */
- (void)setupDatabaseWithName:(NSString*)dbName;

/**
 *  Return the name of the database.
 *
 *  @return Database name.
 */
- (NSString*)getDdName;

/**
 *  Return the path of the database.
 *
 *  @return Path of the database.
 */
- (NSString*)getDdPath;

/**
 *  Database connector.
 *
 *  @return Database connector.
 */
- (FMDatabase*)database;

/**
 *  Check if the database file exists.
 *
 *  @return Return YES if the database exists.
 */
- (BOOL)databaseExists;

/**
 *  Remove the database.
 *
 *  @return Remove the database.
 */
- (BOOL)removeDatabase;

@end
