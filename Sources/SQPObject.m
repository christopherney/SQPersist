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
- (void)SQPAddColumn:(SQPProperty*)column intoTable:(NSString*)tableName;
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
+ (NSMutableArray*)SQPFetchAllForTable:(NSString*)tableName andClassName:(NSString*)className Where:(NSString*)queryOptions orderBy:(NSString*)orderOptions pageIndex:(NSInteger)pageIndex itemsPerPage:(NSInteger)itemsPerPage;
+ (id)SQPFetchOneForTable:(NSString*)tableName andClassName:(NSString*)className Where:(NSString*)queryOptions;
+ (void)logRequest:(NSString*)request;
@end

/**
 *  Entity object.
 */
@implementation SQPObject

/**
 *  Initiliazation.
 *
 *  @return Entity object.
 */
-(id)init {
    
    if ([super init]) {
        [self SQPInitialization];
    }
    return self;
}

/**
 *  Create an entity of your object.
 *
 *  @return Entity object
 */
+ (id)SQPCreateEntity {
    
    NSString *className = NSStringFromClass([self class]);
    
    id entity = [SQPObject SQPObjectFromClassName:className];
    
    return entity;
}

/**
 *  Initiliazation (private method).
 *
 *  @return Entity object.
 */
- (void)SQPInitialization {
    
    [self SQPClassOfObject:self];
    
    self.SQPProperties = [NSArray arrayWithArray:[self SQPAnalyseProperties]];
    
    [self SQPCreateTable];
}

/**
 *  Set the class name and table name of the object (private method).
 *
 *  @param object Entity object.
 */
- (void)SQPClassOfObject:(SQPObject*)object {
    
    object.SQPClassName = NSStringFromClass([object class]);
    object.SQPTableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, object.SQPClassName];
}

/**
 *  Get all Objective-C properties of entity object (private method).
 *
 *  @return Objective-C properties array.
 */
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
    }
    
    free(properties);
    
    return props;
}

/**
 *  Create the associed table of entity object into the database (private method).
 */
- (void)SQPCreateTable {
    
    if ([self.SQPProperties count] > 0) {
        
        FMDatabase *db = [[SQPDatabase sharedInstance] database];
        
        // If table not exists :
        if ([db tableExists:self.SQPTableName] == NO) {
 
            NSMutableString *sqlColumns = [[NSMutableString alloc] initWithFormat:@"%@ TEXT", kSQPObjectIDName];
            
            for (SQPProperty *property in self.SQPProperties) {

                [sqlColumns appendFormat:@", %@ %@", property.name, [property getSQLiteType]];
            }
            
            NSMutableString *sqlCreateTable = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (%@)", self.SQPTableName, sqlColumns];
            
            // Log SQL request :
            if ([SQPDatabase sharedInstance].logRequests) {
                [SQPObject logRequest:sqlCreateTable];
            }
            
            if ([db executeUpdate:sqlCreateTable] == NO) {
                NSLog(@"%@", [db lastErrorMessage]);
            }
            
        } else if ([SQPDatabase sharedInstance].addMissingColumns == YES) {
            
            // Table current schema :
            FMResultSet *s = [db getTableSchema:self.SQPTableName];
            NSMutableArray *existingColumns = [[NSMutableArray alloc] init];
            
            while ([s next]) {
                NSString *columnName = [s stringForColumn:@"name"];
                [existingColumns addObject:columnName];
            }
            
            for (SQPProperty *property in self.SQPProperties) {
                
                if (property.isCompatibleType == YES) {
                    
                    BOOL exists = NO;
                    
                    for (NSString *columnName in existingColumns) {
                        
                        if ([columnName isEqualToString:property.name]) {
                            exists = YES;
                            break;
                        }
                    }
                    
                    if (exists == NO) {
                        [self SQPAddColumn:property intoTable:self.SQPTableName];
                    }
                }
            }
        }
    }
}

/**
 *  Add new column to the table (private method).
 *
 *  @param column    Column (entity property) to add.
 *  @param tableName Table name to edit (ALTER TABLE)
 */
- (void)SQPAddColumn:(SQPProperty *)column intoTable:(NSString *)tableName {
    
    if (column != nil && [tableName length] > 0) {
        
        FMDatabase *db = [[SQPDatabase sharedInstance] database];
        
        if ([db tableExists:self.SQPTableName] == YES) {
        
            NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, column.name, [column getSQLiteType]];
            
            // Log SQL request :
            if ([SQPDatabase sharedInstance].logRequests) {
                [SQPObject logRequest:sql];
            }
            
            if ([db executeUpdate:sql] == NO) {
                NSLog(@"%@", [db lastErrorMessage]);
            }
        }
    }
}

/**
 *  Save the modification of the entity object.
 *
 *  @return Return YES if the changes apply with succes.
 */
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

/**
 *  Delete the entity into the database.
 *
 *  @return Return YES if the changes apply with succes.
 */
- (BOOL)SQPDeleteEntity {

    self.deleteObject = YES;
    
    return [self SQPSaveEntity];
}

/**
 *  Save children entities of current entity object (private method - call by method named SQPSaveEntity).
 */
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

/**
 *  Cast the Objective-C value to SQLite compatible type (private method).
 *
 *  @param value Objective-C value.
 *
 *  @return SQLite Compatible type.
 */
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
            
        } else if ([value isKindOfClass:[NSURL class]]) {
            
            NSURL *url = (NSURL*)value;
            NSString *urlString = [url absoluteString];

            return urlString;
            
        } else {
            
            // No cast :
            return value;
        }
    }
}

/**
 *  Insert an entity object into the associated table (private method).
 *
 *  @return Insert of insert (YES = succes).
 */
- (BOOL)SQPInsertObject {
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSMutableDictionary *argsDict = [[NSMutableDictionary alloc] init];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ ", self.SQPTableName];
    
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
    
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    BOOL result = [db executeUpdate:sql withParameterDictionary:argsDict];
    
    if (result == YES) {
        self.objectID = udid;
    }
    
    return result;
}

/**
 *  Update an entity object into the associated table (private method).
 *
 *  @return Result of Update (YES = succes).
 */
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
    
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    BOOL result = [db executeUpdate:sql withParameterDictionary:argsDict];
    
    return result;
}

/**
 *  Delete an entity object into the associated table (private method).
 *
 *  @return Result of Delete (YES = succes).
 */
- (BOOL)SQPDeleteObject {
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@'", self.SQPTableName, kSQPObjectIDName, self.objectID];
    
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    BOOL result = [db executeUpdate:sql];
    
    return result;
}

/**
 *  Return every entities save of table.
 *
 *  @return Array of entities.
 */
+ (NSMutableArray*)SQPFetchAll {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    return [SQPObject SQPFetchAllForTable:tableName andClassName:className Where:nil orderBy:nil pageIndex:0 itemsPerPage:0];
}

/**
 *  Return every entities save of table, with filtering conditions.
 *
 *  @param queryOptions Filtering conditions (clause SQL WHERE).
 *
 *  @return Array of entities.
 */
+ (NSMutableArray*)SQPFetchAllWhere:(NSString*)queryOption {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    return [SQPObject SQPFetchAllForTable:tableName andClassName:className Where:queryOption orderBy:nil pageIndex:0 itemsPerPage:0];
}

/**
 *  Return every entities save of table, with filtering conditions and order.
 *
 *  @param queryOptions Filtering conditions (clause SQL WHERE).
 *  @param orderOptions Ordering conditions (clause SQL ORDER BY).
 *
 *  @return Array of entities.
 */
+ (NSMutableArray*)SQPFetchAllWhere:(NSString*)queryOptions orderBy:(NSString*)orderOptions {
  
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];

    return [SQPObject SQPFetchAllForTable:tableName andClassName:className Where:queryOptions orderBy:orderOptions pageIndex:0 itemsPerPage:0];
}

/**
 *  Return every entities save of table, with filtering conditions and order, and pagination system.
 *
 *  @param queryOptions Filtering conditions (clause SQL WHERE).
 *  @param orderOptions Ordering conditions (clause SQL ORDER BY).
 *  @param pageIndex    Page index (start at 0 value).
 *  @param itemsPerPage Number of items per page.
 *
 *  @return Array of entities.
 */
+ (NSMutableArray*)SQPFetchAllWhere:(NSString*)queryOptions orderBy:(NSString*)orderOptions pageIndex:(NSInteger)pageIndex itemsPerPage:(NSInteger)itemsPerPage {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    return [SQPObject SQPFetchAllForTable:tableName andClassName:className Where:queryOptions orderBy:orderOptions pageIndex:pageIndex itemsPerPage:itemsPerPage];
}

/**
 *  Return every entities save of table, with filtering conditions and order, and pagination system (private method).
 *
 *  @param tableName    Table name
 *  @param className    Objective-C class name (entity).
 *  @param queryOptions Filtering conditions (clause SQL WHERE).
 *  @param orderOptions Ordering conditions (clause SQL ORDER BY).
 *  @param pageIndex    Page index (start at 0 value).
 *  @param itemsPerPage Number of items per page.
 *
 *  @return Array of entities.
 */
+ (NSMutableArray*)SQPFetchAllForTable:(NSString*)tableName andClassName:(NSString*)className Where:(NSString*)queryOptions orderBy:(NSString*)orderOptions pageIndex:(NSInteger)pageIndex itemsPerPage:(NSInteger)itemsPerPage {
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM %@", tableName];
    
    if (queryOptions != nil) [sql appendFormat:@" WHERE %@", queryOptions];
    
    if (orderOptions != nil) [sql appendFormat:@" ORDER BY %@", orderOptions];
   
    if (itemsPerPage > 0) {
        NSInteger offset = (pageIndex) * itemsPerPage;
        [sql appendFormat:@" LIMIT %li, %li", (long)offset, (long)itemsPerPage];
    }
    
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    FMResultSet *s = [db executeQuery:sql];
    
    while ([s next]) {
        
        SQPObject *object = [self SQPObjectFromClassName:className];
        [object completeWithResultSet:s];
        [items addObject:object];
    }
    
    return items;
}

/**
 *  Return one entity object by filtering conditions.
 *
 *  @param queryOptions Filtering conditions (clause SQL WHERE).
 *
 *  @return The resulting entity object.
 */
+ (id)SQPFetchOneWhere:(NSString*)queryOptions {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    return [SQPObject SQPFetchOneForTable:tableName andClassName:className Where:queryOptions];
}

/**
 *  Return one entity object.
 *
 *  @param objectID Unique entity object identifier.
 *
 *  @return The resulting entity object.
 */
+ (id)SQPFetchOneByID:(NSString*)objectID {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    NSString *queryOptions = [NSString stringWithFormat:@"%@ = '%@'", kSQPObjectIDName, objectID];
    
    return [SQPObject SQPFetchOneForTable:tableName andClassName:className Where:queryOptions];
}

/**
 *  Return one entity object where the attribute is equal to the value.
 *
 *  @param attribut Attribut name (entity object property name).
 *  @param value    Value of attribut.
 *
 *  @return The resulting entity object.
 */
+ (id)SQPFetchOneByAttribut:(NSString*)attribut withValue:(NSString*)value {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    NSString *queryOptions = [NSString stringWithFormat:@"%@ = '%@'", attribut, value];
    
    return [SQPObject SQPFetchOneForTable:tableName andClassName:className Where:queryOptions];
}

/**
 *  Return one entity object by filtering conditions (private method).
 *
 *  @param tableName    Table name.
 *  @param className    Entity object class name.
 *  @param queryOptions Filtering conditions (clause SQL WHERE).
 *
 *  @return The resulting entity object.
 */
+ (id)SQPFetchOneForTable:(NSString*)tableName andClassName:(NSString*)className Where:(NSString*)queryOptions {
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@", tableName, queryOptions];
    
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    FMResultSet *s = [db executeQuery:sql];
    
    SQPObject *object;
    
    while ([s next]) {
        object = [SQPObject SQPObjectFromClassName:className];
        [object completeWithResultSet:s];
        break;
    }
    
    return object;
}

/**
 *  Return the number of entities save into the associated table.
 *
 *  @return Number of entities.
 */
+ (long long)SQPCountAll {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) AS total_entities FROM %@", tableName];
    
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    FMResultSet *s = [db executeQuery:sql];
    
    long long numberEntities = 0;
    
    while ([s next]) {
        numberEntities = [s longLongIntForColumn:@"total_entities"];
        break;
    }
    
    return numberEntities;
}

/**
 *  Return the number of entities save into the associated table, with filtering conditions.
 *
 *  @param queryOptions Filtering conditions (clause SQL WHERE).
 *
 *  @return Number of entities.
 */
+ (long long)SQPCountAllWhere:(NSString*)queryOptions {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) AS total_entities FROM %@ WHERE %@", tableName, queryOptions];
  
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    FMResultSet *s = [db executeQuery:sql];
    
    long long numberEntities = 0;
    
    while ([s next]) {
        numberEntities = [s longLongIntForColumn:@"total_entities"];
        break;
    }
    
    return numberEntities;
}

/**
 *  Remove all entities of the table (TRUNCATE).
 *
 *  @return Return YES when the table is truncate.
 */
+ (BOOL)SQPTruncateAll {
    
    NSString *className = NSStringFromClass([self class]);
    NSString *tableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, className];
    
    FMDatabase *db = [[SQPDatabase sharedInstance] database];
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
    
    // Log SQL request :
    if ([SQPDatabase sharedInstance].logRequests) {
        [SQPObject logRequest:sql];
    }
    
    BOOL result = [db executeUpdate:sql];
    
    return result;
}

/**
 *  Set all entity properties with ResultSet of SQL query (private method).
 *
 *  @param resultSet ResultSet of SQL query.
 */
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
                
                if (imageData != nil) {
                    
                    UIImage *image = [UIImage imageWithData:imageData];
                    [self setValue:image forKey:property.name];
                }
          
            } else if (property.type == kPropertyTypeURL) {

                if ([value isKindOfClass:[NSString class]]) {
                    
                    NSString *urlString = (NSString*)value;
                    NSURL *url = [NSURL URLWithString:urlString];
                    
                    [self setValue:url forKey:property.name];
                }
                
            } else {
                
                [self setValue:value forKey:property.name];
            }
            
        }
    }
    
    self.objectID = [resultSet stringForColumn:kSQPObjectIDName];
}

/**
 *  Set all entity properties with ResultSet of SQL query (private method).
 *
 *  @param object    Entity object to set.
 *  @param resultSet ResultSet of SQL query.
 */
- (void)completeObject:(SQPObject*)object withResultSet:(FMResultSet*)resultSet {
    
    [object completeWithResultSet:resultSet];
}

/**
 *  Generate un unique identifier (private method).
 *
 *  @return Unique identifier.
 */
- (NSString *)uuidString {

    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    return uuidString;
}

/**
 *  Allocate an initialize an entity object from class name (private method).
 *
 *  @param className Class name.
 *
 *  @return Entity object allocated and initialized.
 */
+ (SQPObject*)SQPObjectFromClassName:(NSString*)className {
    
    Class theClass = NSClassFromString(className);
    
    SQPObject *object = (SQPObject*)[[theClass alloc] init];
 
    return object;
}

/**
 *  Log the SQL request in Xcode output console.
 *
 *  @param request SQL request.
 */
+ (void)logRequest:(NSString*)request {
    NSLog(@"SQPersist : %@", request);
}

@end
