//
//  SQPProperty.h
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef enum SQPPropertyType : NSUInteger {
    kPropertyTypeInt,
    kPropertyTypeLong,
    kPropertyTypeLongLong,
    kPropertyTypeBool,
    kPropertyTypeDouble,
    kPropertyTypeFloat,
    kPropertyTypeChar,
    kPropertyTypeShort,
    kPropertyTypeNumber,
    kPropertyTypeDecimalNumber,
    kPropertyTypeString,
    kPropertyTypeDate,
    kPropertyTypeData,
    kPropertyTypeArray,
    kPropertyTypeMutableArray,
    kPropertyTypeImage,
    kPropertyTypeURL,
    kPropertyTypeObject
} SQPPropertyType;

@interface SQPProperty : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id value;
@property (nonatomic) SQPPropertyType type;
@property (nonatomic) BOOL isPrimitive;
@property (nonatomic) BOOL isNonatomic;
@property (nonatomic) BOOL isSQPObject;

- (void)getPropertyType:(const char *)attributes;

- (NSString*)getSQLiteType;

@end
