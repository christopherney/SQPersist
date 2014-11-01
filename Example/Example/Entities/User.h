//
//  User.h
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SQPObject.h"

#import "Car.h"

@interface User : SQPObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic) NSInteger gender;
@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic) BOOL isEnable;
@property (nonatomic, strong) NSNumber *numberFriends;
@property (nonatomic) char letter;
@property (nonatomic) short smallNumber;
@property (nonatomic) long longNumber;
@property (nonatomic) long long veryLongNumber;
@property (nonatomic) float amount;
@property (nonatomic, strong) NSDecimalNumber *decimalNumber;

@property (nonatomic) id unknowObject;
@property (nonatomic, strong) NSArray *parents;
@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) NSData *picture;
@property (nonatomic, strong) UIImage *photo;

@property (nonatomic, strong) Car *myCar;

@end
