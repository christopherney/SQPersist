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

/**
 *  Database manager.
 */
@interface SQPDatabase : NSObject {
    
    /**
     *  FMDB Database connector.
     */
    FMDatabase *_database;
    
    /**
     *  Database name.
     */
    NSString *_dbName;
    
    /**
     *  Database filepath.
     */
    NSString *_dbPath;
}

/**
 *  If enable to YES, the system will check and add missing columns into the database table.
 *  Warning : execute may queries. Please desactive this option after your tables updates.
 */
@property (nonatomic) BOOL addMissingColumns;

/**
 *  Indication if the genrated SQL requests are logged.
 */
@property (nonatomic) BOOL logRequests;

/**
 *  Get the main instance of the database manager.
 *
 *  @return Instance.
 */
+ (SQPDatabase*)sharedInstance;

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
