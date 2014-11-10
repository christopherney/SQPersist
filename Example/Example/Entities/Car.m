//
//  Car.m
//  SQPersist
//
//  Created by Christopher Ney on 30/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "Car.h"

@implementation Car

- (id)defaultValueForProperty:(SQPProperty *)property {
    
    if ([property.name isEqualToString:@"urlLogo"]) {
        return @"http://www.gogole.fr/";
    } else {
        return nil;
    }
}

@end
