//
//  SQPDatabase.m
//  SQPersist
//
//  Created by Christopher Ney on 30/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "SQPDatabase.h"

#define kSQPDatabaseName @"SQPersist.db"

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

- (id)init {
    
    if ([super init]) {
        _database = [self createDatabase];
    }
    return self;
}

- (FMDatabase*)createDatabase {
    
    NSString *documentdir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    _dbPath = [documentdir stringByAppendingPathComponent:kSQPDatabaseName];
    
    NSLog(@"%@", _dbPath);
    
    FMDatabase *db = [FMDatabase databaseWithPath:_dbPath];
    db.logsErrors = YES;
    db.traceExecution = YES;
    
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
