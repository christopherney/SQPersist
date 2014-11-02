//
//  ViewController.h
//  Example
//
//  Created by Christopher Ney on 01/11/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootTableViewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, strong) NSMutableArray *items;

@property (nonatomic) NSInteger orderLastIndex;
@property (nonatomic, strong) NSString *orderProperty;
@property (nonatomic) BOOL orderDirection;

@property (nonatomic, strong) NSString *where;

#pragma mark - Actions

- (IBAction)actionAddEntity:(id)sender;

@end

