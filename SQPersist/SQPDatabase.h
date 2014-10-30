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
    NSString *_dbPath;
}

+ (id)sharedInstance;

- (FMDatabase*)database;

- (BOOL)removeDatabase;

@end
