//
//  SQPDatabase.m
//  SQPersist
//
//  Created by Christopher Ney on 30/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "SQPDatabase.h"

#define kSQPDefaultDdName @"SQPersist.db"

@interface SQPDatabase ()
- (FMDatabase*)createDatabase;
@end

@implementation SQPDatabase

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

- (void)setupDatabaseWithName:(NSString*)dbName {
 
    _dbName = dbName;
    _database = [self createDatabase];
}

- (NSString*)getDdName {
    return _dbName;
}

- (NSString*)getDdPath {
    return _dbPath;
}

- (id)init {
    
    if ([super init]) {
       
    }
    return self;
}

- (FMDatabase*)createDatabase {
    
    if (_dbName == nil) _dbName = kSQPDefaultDdName;
    
    NSString *documentdir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    _dbPath = [documentdir stringByAppendingPathComponent:_dbName];
    
    //NSLog(@"%@", _dbPath);
    
    FMDatabase *db = [FMDatabase databaseWithPath:_dbPath];
    db.logsErrors = YES;
    db.traceExecution = NO;
    
    if (![db open]) {
        return nil;
    } else {
        return db;
    }
}

- (FMDatabase*)database {
    
    if (_database == nil) {
        _database = [self createDatabase];
    }
    
    return _database;
}

- (BOOL)databaseExists {
 
    if (_dbPath != nil) {
        return [[NSFileManager defaultManager] fileExistsAtPath:_dbPath isDirectory:NO];
    } else {
        return NO;
    }
}

- (BOOL)removeDatabase {
    
    if (_dbPath != nil) {
        
        if (_database != nil) {
            [_database close];
        }
        
        NSError *error = nil;
        
        [[NSFileManager defaultManager] removeItemAtPath:_dbPath error:&error];
        
        if (error == nil) {
            _database = nil;
            return YES;
        } else {
            NSLog(@"%@", [error localizedDescription]);
            return NO;
        }
        
    } else {
        return NO;
    }
}

@end
