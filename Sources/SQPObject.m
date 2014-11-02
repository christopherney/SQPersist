//
//  SQPObject.m
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "SQPObject.h"
#import "SQPProperty.h"

#define kSQPObjectIDName @"objectID"
#define kSQPTablePrefix @"SQP"

@interface SQPObject ()
- (void)completeWithResultSet:(FMResultSet*)resultSet;
- (void)SQPCreateTable;
- (void)SQPInitialization;
- (NSMutableArray *)SQPAnalyseProperties;
- (void)SQPClassOfObject:(SQPObject*)object;
- (NSString *)uuidString;
+ (SQPObject*)SQPObjectFromClassName:(NSString*)className;
- (void)completeObject:(SQPObject*)object withResultSet:(FMResultSet*)resultSet;
- (id)objcObjectToSQLite:(id)value;
- (BOOL)SQPInsertObject;
- (BOOL)SQPUpdateObject;
- (BOOL)SQPDeleteObject;
- (void)SQPSaveChildren;
+ (NSMutableArray*)SQPFetchAllForTable:(NSString*)tableName andClassName:(NSString*)className Where:(NSString*)queryOptions orderBy:(NSString*)orderOptions;
@end

@implementation SQPObject

-(id)init {
    
    if ([super init]) {
        [self SQPInitialization];
    }
    return self;
}

+ (id)SQPCreateEntity {
    
    NSString *className = NSStringFromClass([self class]);
    
    id entity = [SQPObject SQPObjectFromClassName:className];
    
    return entity;
}

- (void)SQPInitialization {
    
    [self SQPClassOfObject:self];
    
    self.SQPProperties = [NSArray arrayWithArray:[self SQPAnalyseProperties]];
    
    [self SQPCreateTable];
}

- (void)SQPClassOfObject:(SQPObject*)object {
    
    object.SQPClassName = NSStringFromClass([object class]);
    object.SQPTableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, object.SQPClassName];
}

- (NSMutableArray *)SQPAnalyseProperties {
    
    NSMutableArray *props = [NSMutableArray array];
    
    unsigned int outCount, i;
    
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (i = 0; i < outCount; i++) {
        
        objc_property_t property = properties[i];
        
        NSString *propertyName = [NSString stringWithFormat:@"%s", property_getName(property)];
        
        id propertyValue = [self valueForKey:(NSString *)propertyName];
        
        SQPProperty *prop = [[SQPProperty alloc] init];
        [prop getPropertyType:property_getAttributes(property)];
        prop.name = propertyName;
        prop.value = propertyValue;
        
        [props addObject:prop];
        
        //NSLog(@"%@", [prop description]);
    }
    
    free(properties);
    
    return props;
}

- (void)SQPCreateTable {
    
    if ([self.SQPProperties count] > 0) {
        
        FMDatabase *db = [[SQPDatabase sharedInstance] database];
        
        if ([db tableExists:self.SQPTableName] == NO) {
 
            NSMutableString *sqlColumns = [[NSMutableString alloc] initWithFormat:@"%@ TEXT", kSQPObjectIDName];
            
            for (SQPProperty *property in self.SQPProperties) {

                [sqlColumns appendFormat:@", %@ %@", property.name, [property getSQLiteType]];
            }
            
            NSMutableString *sqlCreateTable = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (%@)", self.SQPTableName, sqlColumns];
            
            if ([db executeUpdate:sqlCreateTable]) {
                
            }
            
        }
    }
}

- (BOOL)SQPSaveEntity {
    
    BOOL result = NO;
    
    if (self.deleteObject == YES) {
        result = [self SQPDeleteObject];
    } else {
        
        if ([self.objectID length] > 0) {
            result = [self SQPUpdateObject];
        } else {
            result = [self SQPInsertObject];
        }
    }

    if (result == YES) {
        [self SQPSaveChildren];
    }
 
    return result;
}

- (void)SQPSaveChildren {
    
    if (self.SQPProperties != nil) {
        
        for (SQPProperty *property in self.SQPProperties) {
            
            // If Array :
            if (property.type == kPropertyTypeArray || property.type == kPropertyTypeMutableArray) {
                
                NSArray *items = (NSArray*)[self valueForKey:property.name];
                
                if (items != nil) {
                    
                    if ([items isKindOfClass:[NSArray class]] || [items isKindOfClass:[NSMutableArray class]]) {
                        
                        for (NSObject *item in items) {
                            
                            if ([item isKindOfClass:[SQPObject class]]) {
                                
                                SQPObject *sqpObject = (SQPObject*)item;
                                [sqpObject SQPSaveEntity];
                            }
                        }
                    }
                }
                
            // If Object :
            } else if (property.type == kPropertyTypeObject) {
                
                NSObject *item = (NSObject*)[self valueForKey:property.name];
                
                if (item != nil) {
                    
                    if ([item isKindOfClass:[SQPObject class]]) {
                        
                        SQPObject *sqpObject = (SQPObject*)item;
                        [sqpObject SQPSaveEntity];
                    }
                }
                
            }
        }
    }
}

- (id)objcObjectToSQLite:(id)value {
    
    if (value == nil) {
        
        return [NSNull null];
        
    } else {
        
        // Convert Date to timestamp :
        if ([value isKindOfClass:[NSDate class]]) {
            
            NSDate *dateValue = (NSDate*)value;
            return [NSNumber numberWithInt:[dateValue timeIntervalSince1970]];
            
        } else if ([value isKindOfClass:[UIImage class]]) {
            
            UIImage *imageValue = (UIImage*)value;
            NSData *imageData = UIImagePNGRepresentation(imageValue);
            
            if (imageData == nil) {
                imageData = UIImageJPEGRepresentation(imageValue, 1);
            }
            
            return imageData;
            
        } else {
            
            // No cast :
            return value;
        }
    }
}

- (BOOL)SQPInsertObject {
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSMutableDictionary *argsDict = [[NSMutableDictionary alloc] init];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@", self.SQPTableName];
    
    NSMutableString *sqlColumns = [[NSMutableString alloc] init];
    NSMutableString *sqlArgs = [[NSMutableString alloc] init];
    
    for (SQPProperty *property in self.SQPProperties) {
        
        if ([sqlArgs length] == 0) {
            [sqlArgs appendFormat:@":%@", property.name];
            [sqlColumns appendString:property.name];
        } else {
            [sqlColumns appendFormat:@", %@", property.name];
            [sqlArgs appendFormat:@", :%@", property.name];
        }
        
        id propertyValue = [self valueForKey:property.name];
        
        id sqliteValue = [self objcObjectToSQLite:propertyValue];
        
        [argsDict setObject:sqliteValue forKey:property.name];
    }
    
    // Object ID (UUID) :
    NSString *udid = [self uuidString];
    [sqlColumns appendFormat:@", %@", kSQPObjectIDName];
    [sqlArgs appendFormat:@", :%@", kSQPObjectIDName];
    [argsDict setObject:udid forKey:kSQPObjectIDName];
    
    
    [sql appendFormat:@"(%@) VALUES (%@)", sqlColumns, sqlArgs];
    
    BOOL result = [db executeUpdate:sql withParameterDictionary:argsDict];
    
    if (result == YES) {
        self.objectID = udid;
    }
    
    return result;
}

- (BOOL)SQPUpdateObject {

    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSMutableDictionary *argsDict = [[NSMutableDictionary alloc] init];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ", self.SQPTableName];
    
    NSMutableString *sqlArgs = [[NSMutableString alloc] init];
    
    for (SQPProperty *property in self.SQPProperties) {
        
        if ([sqlArgs length] == 0) {
            [sqlArgs appendFormat:@"%@ = :%@", property.name, property.name];
        } else {
            [sqlArgs appendFormat:@", %@ = :%@", property.name, property.name];
        }

        id propertyValue = [self valueForKey:property.name];
        
        id sqliteValue = [self objcObjectToSQLite:propertyValue];
        
        [argsDict setObject:sqliteValue forKey:property.name];
    }

    [sql appendFormat:@"%@ WHERE %@ = '%@'", sqlArgs, kSQPObjectIDName, self.objectID];
    
    BOOL result = [db executeUpdate:sql withParameterDictionary:argsDict];
    
    return result;
}

- (BOOL)SQPDeleteObject {
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@'", self.SQPTableName, kSQPObjectIDName, self.objectID];
    
    BOOL result = [db executeUpdate:sql];
    
    return result;
}

+ (NSMutableArray*)SQPFetchAll {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    return [SQPObject SQPFetchAllForTable:tableName andClassName:className Where:nil orderBy:nil];
}

+ (NSMutableArray*)SQPFetchAllWhere:(NSString*)queryOption {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    return [SQPObject SQPFetchAllForTable:tableName andClassName:className Where:queryOption orderBy:nil];
}

+ (NSMutableArray*)SQPFetchAllWhere:(NSString*)queryOptions orderBy:(NSString*)orderOptions {
  
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];

    return [SQPObject SQPFetchAllForTable:tableName andClassName:className Where:queryOptions orderBy:orderOptions];
}

+ (NSMutableArray*)SQPFetchAllForTable:(NSString*)tableName andClassName:(NSString*)className Where:(NSString*)queryOptions orderBy:(NSString*)orderOptions {
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM %@", tableName];
    
    if (queryOptions != nil) [sql appendFormat:@" WHERE %@", queryOptions];
    
    if (orderOptions != nil) [sql appendFormat:@" ORDER BY %@", orderOptions];
    
    FMResultSet *s = [db executeQuery:sql];
    
    while ([s next]) {
        
        SQPObject *object = [self SQPObjectFromClassName:className];
        [object completeWithResultSet:s];
        [items addObject:object];
    }
    
    return items;
}

+ (id)SQPFetchOneWhere:(NSString*)queryOptions {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableName, queryOptions];
    
    FMResultSet *s = [db executeQuery:sql];
    
    SQPObject *object;
    
    while ([s next]) {
        object = [SQPObject SQPObjectFromClassName:className];
        [object completeWithResultSet:s];
        break;
    }
    
    return object;
}

+ (id)SQPFetchOneByID:(NSString*)objectID {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = '%@'", tableName, kSQPObjectIDName, objectID];
    
    FMResultSet *s = [db executeQuery:sql];
    
    SQPObject *object;
    
    while ([s next]) {
        object = [SQPObject SQPObjectFromClassName:className];
        [object completeWithResultSet:s];
        break;
    }
    
    return object;
}

+ (long long)SQPCountAll {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) AS total_entities FROM %@", tableName];
    
    FMResultSet *s = [db executeQuery:sql];
    
    long long numberEntities = 0;
    
    while ([s next]) {
        numberEntities = [s longLongIntForColumn:@"total_entities"];
        break;
    }
    
    return numberEntities;
}

+ (long long)SQPCountAllWhere:(NSString*)queryOptions {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) AS total_entities FROM %@ WHERE %@", tableName, queryOptions];
    
    FMResultSet *s = [db executeQuery:sql];
    
    long long numberEntities = 0;
    
    while ([s next]) {
        numberEntities = [s longLongIntForColumn:@"total_entities"];
        break;
    }
    
    return numberEntities;
}

+ (BOOL)SQPTruncateAll {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
    
    BOOL result = [db executeUpdate:sql];
    
    return result;
}

- (void)completeWithResultSet:(FMResultSet*)resultSet {
    
    for (SQPProperty *property in self.SQPProperties) {
        
        id value = [resultSet objectForColumnName:property.name];
        
        if (value != nil && property.type != kPropertyTypeChar) {
            
            // Convert Date to timestamp :
            if (property.type == kPropertyTypeDate) {
                
                NSNumber *interval = (NSNumber*)value;
                NSDate *dateValue = [[NSDate alloc] initWithTimeIntervalSince1970:[interval integerValue]];
                
                [self setValue:dateValue forKey:property.name];
                
            } else if (property.type == kPropertyTypeImage) {
                
                NSData *imageData = (NSData*)value;
                UIImage *image = [UIImage imageWithData:imageData];
                
                [self setValue:image forKey:property.name];
                
            } else {
                
                [self setValue:value forKey:property.name];
            }
  
        }
    }
    
    self.objectID = [resultSet stringForColumn:kSQPObjectIDName];
}

- (void)completeObject:(SQPObject*)object withResultSet:(FMResultSet*)resultSet {
    
    [object completeWithResultSet:resultSet];
}

- (NSString *)uuidString {

    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    return uuidString;
}

+ (SQPObject*)SQPObjectFromClassName:(NSString*)className {
    
    Class theClass = NSClassFromString(className);
    
    SQPObject *object = (SQPObject*)[[theClass alloc] init];
 
    return object;
}



@end
