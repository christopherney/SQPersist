//
//  ViewController.m
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "ViewController.h"

#import "User.h"
#import "Car.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // REMOVE Local Database :
    [[SQPDatabase sharedInstance] removeDatabase];
    
    User *userCreated = [[User alloc] init];
    userCreated.firstName = @"Christopher";
    userCreated.lastName = @"Ney";
    
    // INSERT Object :
    [userCreated SQPSaveEntity];
    
    // SELECT BY objectID :
    User *userSelected = (User*)[User SQPFetchOneByID:userCreated.objectID];
    userSelected.amount = 10.50f;
    
    // UPDATE Object :
    [userSelected SQPSaveEntity];
    
    Car *car1 = [[Car alloc] init];
    car1.name = @"Ferrari";
    car1.color = @"Red";
    [car1 SQPSaveEntity]; // INSERT Object
    
    Car *car2 = [[Car alloc] init];
    car2.name = @"BMW";
    car2.color = @"Black";
    [car2 SQPSaveEntity]; // INSERT Object
    
    Car *car3 = [[Car alloc] init];
    car3.name = @"Ferrari";
    car3.color = @"Yellow";
    [car3 SQPSaveEntity]; // INSERT Object
    
    // DELETE Object :
    car3.deleteObject = YES;
    [car3 SQPSaveEntity];
    
    // SELECT ALL 'Ferrari' :
    NSMutableArray *cars = [Car SQPFetchAllWhere:@"name = 'Ferrari'"];
    
    NSLog(@"Number of cars: %d", [cars count]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
