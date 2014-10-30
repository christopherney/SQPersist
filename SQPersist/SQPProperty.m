//
//  SQPProperty.m
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "SQPProperty.h"

#define kAttributeInt @"Tq"
#define kAttributeBool @"TB"
#define kAttributeChar @"Tc"
#define kAttributeShort @"Ts"
#define kAttributeLong @"Tq"
#define kAttributeLongLong @"Tq"
#define kAttributeFloat @"Tf"

#define kAttributeNSNumber @"T@\"NSNumber\""
#define kAttributeNSDecimalNumber @"T@\"NSDecimalNumber\""
#define kAttributeNSString @"T@\"NSString\""
#define kAttributeNSDate @"T@\"NSDate\""
#define kAttributeNSData @"T@\"NSData\""
#define kAttributeNSArray @"T@\"NSArray\""
#define kAttributeNSMutableArray @"T@\"NSMutableArray\""
#define kAttributeObject @"T@"

@interface SQPProperty ()
- (BOOL)string:(NSString*)s containsSubString:(NSString*)ss;
- (NSString*)propertyTypeToString:(SQPPropertyType)type;
@end

@implementation SQPProperty

- (void)getPropertyType:(const char *)attributes {
    
    NSString *propertyAttributes = [NSString stringWithFormat:@"%s", attributes];
    
    // Si c'est un type primitif :
    if ([self string:propertyAttributes containsSubString:@",&,"]) {
        
        self.isPrimitive = NO;
        
        if ([self string:propertyAttributes containsSubString:kAttributeNSNumber]) {
            self.type = kPropertyTypeNumber;
        } else if ([self string:propertyAttributes containsSubString:kAttributeNSDecimalNumber]) {
            self.type = kPropertyTypeDecimalNumber;
        } else if ([self string:propertyAttributes containsSubString:kAttributeNSString]) {
            self.type = kPropertyTypeString;
        } else if ([self string:propertyAttributes containsSubString:kAttributeNSDate]) {
            self.type = kPropertyTypeDate;
        } else if ([self string:propertyAttributes containsSubString:kAttributeNSData]) {
            self.type = kPropertyTypeData;
        } else if ([self string:propertyAttributes containsSubString:kAttributeNSArray]) {
            self.type = kPropertyTypeArray;
        } else if ([self string:propertyAttributes containsSubString:kAttributeNSMutableArray]) {
            self.type = kPropertyTypeMutableArray;
        } else if ([self string:propertyAttributes containsSubString:kAttributeObject]) {
            self.type = kPropertyTypeObject;
        }
        
    } else {
        
        self.isPrimitive = YES;
        
        if ([self string:propertyAttributes containsSubString:kAttributeInt]) {
            self.type = kPropertyTypeInt;
        } else if ([self string:propertyAttributes containsSubString:kAttributeBool]) {
            self.type = kPropertyTypeBool;
        } else if ([self string:propertyAttributes containsSubString:kAttributeChar]) {
            self.type = kPropertyTypeChar;
        } else if ([self string:propertyAttributes containsSubString:kAttributeShort]) {
            self.type = kPropertyTypeShort;
        } else if ([self string:propertyAttributes containsSubString:kAttributeLong]) {
            self.type = kPropertyTypeLong;
        } else if ([self string:propertyAttributes containsSubString:kAttributeLongLong]) {
            self.type = kPropertyTypeLongLong;
        } else if ([self string:propertyAttributes containsSubString:kAttributeFloat]) {
            self.type = kPropertyTypeFloat;
        }
        
    }
    
    // Si attirbut Non Atomic :
    if ([self string:propertyAttributes containsSubString:@",N,"]) {
        self.isNonatomic = YES;
    } else {
        self.isNonatomic = NO;
    }
}

- (NSString*)propertyTypeToString:(SQPPropertyType)type {
    
    if (type == kPropertyTypeInt) {
        return @"int";
    } else if (type == kPropertyTypeLong) {
        return @"long";
    } else if (type == kPropertyTypeLongLong) {
        return @"long long";
    } else if (type == kPropertyTypeBool) {
        return @"BOOL";
    } else if (type == kPropertyTypeDouble) {
        return @"double";
    } else if (type == kPropertyTypeFloat) {
        return @"float";
    } else if (type == kPropertyTypeChar) {
        return @"char";
    } else if (type == kPropertyTypeShort) {
        return @"short";
    } else if (type == kPropertyTypeNumber) {
        return @"NSNumber";
    } else if (type == kPropertyTypeDecimalNumber) {
        return @"NSDecimalNumber";
    } else if (type == kPropertyTypeString) {
        return @"NSString";
    } else if (type == kPropertyTypeDate) {
        return @"NSDate";
    } else if (type == kPropertyTypeData) {
        return @"NSData";
    } else if (type == kPropertyTypeArray) {
        return @"NSArray";
    } else if (type == kPropertyTypeMutableArray) {
        return @"NSMutableArray";
    } else if (type == kPropertyTypeObject) {
        return @"id";
    } else {
        return @"unknown";
    }
}

- (NSString*)getSQLiteType {
    
    if (self.type == kPropertyTypeInt) {
        return @"INTEGER";
    } else if (self.type == kPropertyTypeLong) {
        return @"INTEGER";
    } else if (self.type == kPropertyTypeLongLong) {
        return @"INTEGER";
    } else if (self.type == kPropertyTypeBool) {
        return @"INTEGER";
    } else if (self.type == kPropertyTypeDouble) {
        return @"REAL";
    } else if (self.type == kPropertyTypeFloat) {
        return @"REAL";
    } else if (self.type == kPropertyTypeChar) {
        return @"TEXT";
    } else if (self.type == kPropertyTypeShort) {
        return @"INTEGER";
    } else if (self.type == kPropertyTypeNumber) {
        return @"REAL";
    } else if (self.type == kPropertyTypeDecimalNumber) {
        return @"REAL";
    } else if (self.type == kPropertyTypeString) {
        return @"TEXT";
    } else if (self.type == kPropertyTypeDate) {
        return @"INTEGER";
    } else if (self.type == kPropertyTypeData) {
        return @"BLOB";
    } else if (self.type == kPropertyTypeArray) {
        return @"BLOB";
    } else if (self.type == kPropertyTypeMutableArray) {
        return @"BLOB";
    } else if (self.type == kPropertyTypeObject) {
        return @"BLOB";
    } else {
        return @"unknown";
    }
}

- (NSString *)description {
    
    NSMutableString *propertyLine = [[NSMutableString alloc] initWithString:@"@property"];
    
    if (self.isNonatomic) [propertyLine appendString:@" (nonatomic)"];
    
    [propertyLine appendFormat:@" %@", [self propertyTypeToString:self.type]];
    
    if (self.isPrimitive == NO) [propertyLine appendString:@" *"];
    
    [propertyLine appendFormat:@" %@;", self.name];
    
    if (self.value != nil) {
        [propertyLine appendFormat:@" // value = %@", [self.value description]];
    } else {
        [propertyLine appendString:@" // value = (null)"];
    }
    
    return propertyLine;
}

- (BOOL)string:(NSString*)s containsSubString:(NSString*)ss {
    if ([s rangeOfString:ss].location == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}

@end
