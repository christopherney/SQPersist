//
//  ViewController.h
//  Example
//
//  Created by Christopher Ney on 01/11/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *items;

#pragma mark - Actions

- (IBAction)actionAddEntity:(id)sender;

@end

