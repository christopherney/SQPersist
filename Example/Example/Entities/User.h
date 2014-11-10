//
//  User.h
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SQPObject.h"

#import "Car.h"

@interface User : SQPObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic) NSInteger gender;
@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic) BOOL isEnable;
@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) Car *myCar;
@property (nonatomic) CGFloat amount;

@end
