//
//  SQPObject.h
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <objc/objc.h>
#include <objc/NSObjCRuntime.h>

#import "SQPDatabase.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@interface SQPObject : NSObject

@property (nonatomic, strong) NSString *SQPClassName;
@property (nonatomic, strong) NSString *SQPTableName;
@property (nonatomic, strong) NSArray *SQPProperties;

@property (nonatomic, strong) NSString *objectID;
@property (nonatomic) BOOL deleteObject;

- (BOOL)SQPSaveEntity;

+ (NSMutableArray*)SQPFetchAll;

+ (NSMutableArray*)SQPFetchAllWhere:(NSString*)queryOptions;

+ (SQPObject*)SQPFetchOneWhere:(NSString*)queryOptions;

+ (SQPObject*)SQPFetchOneByID:(NSString*)objectID;

@end
