//
//  TestObject.h
//  Example
//
//  Created by Christopher Ney on 02/11/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "SQPObject.h"

@interface TestObject : SQPObject

@property (nonatomic) NSString *testIgnoredProperty; // Property ignored.

@property (nonatomic, strong) NSString* testString; // NSString -> become TEXT into SQLite database
@property (nonatomic, strong) NSNumber* testNumber; // NSNumber -> become REAL into SQLite database
@property (nonatomic, strong) NSDecimalNumber* testDecimalNumber; // NSDecimalNumber -> become REAL into SQLite database
@property (nonatomic, strong) NSDate* testDate; // NSDate -> become INTEGER into SQLite database (Timestamp Since 1970)
@property (nonatomic, strong) NSData* testData; // NSData -> become BLOB into SQLite database
@property (nonatomic, strong) UIImage* testImage; // UIImage -> become BLOB into SQLite database
@property (nonatomic, strong) NSURL* testURL; // NSURL -> become TEXT into SQLite database
@property (nonatomic) int testInt; // int -> become INTEGER into SQLite database
@property (nonatomic) double testDouble; // double -> become REAL into SQLite database
@property (nonatomic) long testLong; // long -> become REAL into SQLite database
@property (nonatomic) long long testLongLong; // long long -> become REAL into SQLite database
@property (nonatomic) short testShort; // short -> become INTEGER into SQLite database
@property (nonatomic) float testFloat; // float -> become REAL into SQLite database

@property (nonatomic) BOOL testBool;

@end
