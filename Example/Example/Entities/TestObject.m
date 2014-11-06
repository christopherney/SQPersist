//
//  TestObject.m
//  Example
//
//  Created by Christopher Ney on 02/11/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "TestObject.h"

@implementation TestObject

- (BOOL)ignoredProperty:(SQPProperty*)property {
    
    if ([property.name isEqualToString:@"testIgnoredProperty"]) {
        return YES;
    } else {
        return NO;
    }
}

@end
