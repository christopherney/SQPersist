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
- (BOOL)SQPInsertObject;
- (BOOL)SQPUpdateObject;
- (BOOL)SQPDeleteObject;
@end

@implementation SQPObject

-(id)init {
    
    if ([super init]) {
        [self SQPInitialization];
    }
    return self;
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
        
        NSLog(@"%@", [prop description]);
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
    
    if (self.deleteObject == YES) {
        return [self SQPDeleteObject];
    } else {
        
        if ([self.objectID length] > 0) {
            return [self SQPUpdateObject];
        } else {
            return [self SQPInsertObject];
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
        
        if (propertyValue != nil) {
            [argsDict setObject:propertyValue forKey:property.name];
        } else {
            [argsDict setObject:[NSNull null] forKey:property.name];
        }
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
    
    /*UPDATE table_name
     SET column1 = value1, column2 = value2...., columnN = valueN
     WHERE [condition];*/
    
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
        
        if (propertyValue != nil) {
            [argsDict setObject:propertyValue forKey:property.name];
        } else {
            [argsDict setObject:[NSNull null] forKey:property.name];
        }
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
    
    return [SQPObject SQPFetchAllWhere:nil];
}

+ (NSMutableArray*)SQPFetchAllWhere:(NSString*)queryOptions {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = nil;
    
    if (queryOptions != nil) {
        sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableName, queryOptions];
    } else {
        sql = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
    }

    FMResultSet *s = [db executeQuery:sql];
    
    while ([s next]) {
    
        SQPObject *object = [self SQPObjectFromClassName:className];
        [object completeWithResultSet:s];
        [items addObject:object];
    }
    
    return items;
}

+ (SQPObject*)SQPFetchOneWhere:(NSString*)queryOptions {
    
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

+ (SQPObject*)SQPFetchOneByID:(NSString*)objectID {
    
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

- (void)completeWithResultSet:(FMResultSet*)resultSet {
    
    for (SQPProperty *property in self.SQPProperties) {
        
        id value = [resultSet objectForColumnName:property.name];
        
        if (value != nil && property.type != kPropertyTypeChar) {
            [self setValue:value forKey:property.name];
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
    
    SEL selector = @selector(alloc);
    
    SQPObject *object = (SQPObject*)[[theClass performSelector:selector] init];
    
    return object;
}



@end
