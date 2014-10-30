//
//  SQPObject.m
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "SQPObject.h"
#import "SQPProperty.h"

#define kSQPTablePrefix @"SQP"
#define kSQPObjectIDName @"objectID"

@interface SQPObject ()
- (void)SQPInitialization;
- (FMDatabase*)SQPDatabase;
- (NSMutableArray *)properties_sqp;
- (void)class_sqp;
- (NSString *)uuidString;
- (SQPObject*)SQPObjectFromClassName:(NSString*)className;
@end

@implementation SQPObject

-(id)init {
    
    if ([super init]) {
        [self SQPInitialization];
    }
    return self;
}

- (void)SQPInitialization {
    
    [self class_sqp];
    
    self.SQPProperties = [NSArray arrayWithArray:[self properties_sqp]];
    
    [self SQPCreateTable];
}

- (void)class_sqp {
    
    self.SQPClassName = NSStringFromClass([self class]);
    self.SQPTableName = [NSString stringWithFormat:@"%@%@", kSQPTablePrefix, self.SQPClassName];
}

- (NSMutableArray *)properties_sqp {
    
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

- (FMDatabase*)SQPDatabase {
    
    NSString *documentdir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dbPath = [documentdir stringByAppendingPathComponent:@"SQPersist.db"];
    
    NSLog(@"%@", dbPath);
    
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    db.logsErrors = YES;
    
    if (![db open]) {
        return nil;
    } else {
        return db;
    }
}

- (void)SQPCreateTable {
    
    if ([self.SQPProperties count] > 0) {
        
        FMDatabase *db = [self SQPDatabase];
        
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
    
    return NO;
}

- (NSArray*)SQPFetchAll:(NSString*)queryOptions {
    
    FMDatabase *db = [self SQPDatabase];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", self.SQPTableName];
    
    FMResultSet *s = [db executeQuery:sql];
    
    while ([s next]) {
        
        for (SQPProperty *property in self.SQPProperties) {
            
            id value = [s objectForColumnName:property.name];
            
            if (value != nil) {
                [self setValue:value forKey:property.name];
            }
        }
    }
    
    return nil;
}

- (SQPObject*)SQPFetchOne:(NSInteger)objectID {
    
    FMDatabase *db = [self SQPDatabase];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %ld", self.SQPTableName, kSQPObjectIDName, (long)objectID];
    
    FMResultSet *s = [db executeQuery:sql];
    
    SQPObject *object = [self SQPObjectFromClassName:self.SQPClassName];
    
    while ([s next]) {
        
        for (SQPProperty *property in self.SQPProperties) {
            
            id value = [s objectForColumnName:property.name];
            
            if (value != nil && property.type != kPropertyTypeChar) {
                [object setValue:value forKey:property.name];
            }
        }
    }
    
    return object;
}

- (NSString *)uuidString {

    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    return uuidString;
}

- (SQPObject*)SQPObjectFromClassName:(NSString*)className {
    
    Class theClass = NSClassFromString(className);
    
    SEL selector = @selector(alloc);
    
    SQPObject *object = (SQPObject*)[[theClass performSelector:selector] init];
    
    return object;
}



@end
