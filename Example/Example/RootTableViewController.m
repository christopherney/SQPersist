//
//  ViewController.m
//  SQPersist
//
//  Created by Christopher Ney on 29/10/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "RootTableViewController.h"

#import "SQPersist.h"

#import "User.h"
#import "Car.h"
#import "Flickr.h"

@interface RootTableViewController ()
-(void)getFlickRandomPhoto;
@end

@implementation RootTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create Database :
    [[SQPDatabase sharedInstance] setupDatabaseWithName:@"SQPersist.db"];
    
    NSLog(@"DB path: %@ ", [[SQPDatabase sharedInstance] getDdPath]);
    
    self.items = [Car SQPFetchAll];
    
    /*
    // If database exists:
    if ([[SQPDatabase sharedInstance] databaseExists]) {
        
        // REMOVE Local Database :
        [[SQPDatabase sharedInstance] removeDatabase];
        
        NSLog(@"DB '%@' removed!", [[SQPDatabase sharedInstance] getDdName]);
    }
    */
    
    // Create Table at the first init (if tbale ne exists) :
    User *userJohn = [User SQPCreateEntity];
    userJohn.firstName = @"John";
    userJohn.lastName = @"McClane";
    userJohn.birthday = [NSDate date];
    userJohn.photo = [UIImage imageNamed:@"Photo"];
    
    // INSERT Object :
    [userJohn SQPSaveEntity];
    
    // SELECT BY objectID (John McClane) :
    User *userSelected = [User SQPFetchOneByID:userJohn.objectID];
    userSelected.amount = 10.50f;
    
    // UPDATE Object :
    [userSelected SQPSaveEntity];
    
    User *friendJohn = [User SQPCreateEntity];
    friendJohn.firstName = @"Hans";
    friendJohn.lastName = @"Gruber";
    
    userJohn.friends = [[NSMutableArray alloc] initWithObjects:friendJohn, nil];
    
    // UPDATE Object :
    [userJohn SQPSaveEntity];
    
    User *userJohn2 = [User SQPFetchOneWhere:@"lastname = 'McClane'"];
    
    NSLog(@"Name user : %@", userJohn2.firstName);
    
    Car *car1 = [self getRandomCar];
    car1.owner = userJohn;
    [car1 SQPSaveEntity]; // INSERT Object
    
    Car *car2 = [self getRandomCar];
    [car2 SQPSaveEntity]; // INSERT Object
    
    Car *car3 = [self getRandomCar];
    [car3 SQPSaveEntity]; // INSERT Object
    
    // DELETE Object :
    car3.deleteObject = YES;
    [car3 SQPSaveEntity];
    
    Car *car4 = [self getRandomCar];
    [car4 SQPSaveEntity]; // INSERT Object
    
    NSLog(@"Total cars : %lld", [Car SQPCountAll]);
    NSLog(@"Total cars 'Ferrari' : %lld", [Car SQPCountAllWhere:@"name = 'Ferrari'"]);
    
    // SELECT ALL 'Ferrari' :
    NSMutableArray *cars = [Car SQPFetchAllWhere:@"name = 'Ferrari'" orderBy:@"power DESC"];
    
    NSLog(@"Number of cars: %lu", (unsigned long)[cars count]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flickr Example 

-(void)getFlickRandomPhoto {
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1"]];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (connectionError == nil) {
            
            NSError *JSONError;
            NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&JSONError];
            
            if (JSONError == nil) {
                
                NSArray *items = [JSONDictionary objectForKey:@"items"];
                NSDictionary *item = [items objectAtIndex:0];
                
                Flickr *flickrItem = [Flickr SQPCreateEntity];
                flickrItem.author = [item objectForKey:@"author"];
                flickrItem.descriptionPhoto = [item objectForKey:@"description"];
                flickrItem.link = [NSURL URLWithString:[item objectForKey:@"link"]];
                flickrItem.photoURL = [NSURL URLWithString:[[item objectForKey:@"media"] objectForKey:@"m"]];
                flickrItem.title = [item objectForKey:@"title"];
                
                [flickrItem SQPSaveEntity];
                
            } else {
                NSLog(@"%@", [JSONError localizedDescription]);
            }
            
            
        } else {
            NSLog(@"%@", [connectionError localizedDescription]);
        }
    }];
}

#pragma mark - Random Car

-(Car*)getRandomCar {
    
    NSMutableArray *constructors = [[NSMutableArray alloc] initWithObjects:@"Ferrari", @"Porsche", @"BMW", @"Lamborghini", @"Mercedes", nil];
    NSMutableArray *colors = [[NSMutableArray alloc] initWithObjects:@"Red", @"Grey", @"Black", @"White", @"Yellow", @"Green", @"Blue", nil];
    NSMutableArray *powers = [[NSMutableArray alloc] initWithObjects:@350, @410, @380, @290, @475, @397, nil];
    
    NSUInteger randomIndexConstructor = arc4random() % [constructors count];
    NSUInteger randomIndexColor = arc4random() % [colors count];
    NSUInteger randomIndexPower = arc4random() % [powers count];
    
    Car *car = [Car SQPCreateEntity];
    car.name = (NSString*)[constructors objectAtIndex:randomIndexConstructor];
    car.color = (NSString*)[colors objectAtIndex:randomIndexColor];
    car.owner = nil;
    car.power = [[powers objectAtIndex:randomIndexPower] intValue];
    //car.urlLogo =
    
    return car;
}

#pragma mark - Actions

- (IBAction)actionAddEntity:(id)sender {
    
    Car *newCar = [self getRandomCar];
    
    [newCar SQPSaveEntity]; // INSERT Object

    if (self.items == nil) self.items = [[NSMutableArray alloc] init];
    
    [self.items addObject:newCar];
    
    [self.tableView reloadData];
}

- (IBAction)actionClearAll:(id)sender {
    
    [Car SQPTruncateAll];
    
    self.where = nil;
    
    self.items = [Car SQPFetchAll];
    
    [self.tableView reloadData];
}

#pragma mark - UISearchBar Delagete

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    self.items = [Car SQPFetchAll];
    
    self.where = nil;
    
    [self.tableView reloadData];
    
    [searchBar resignFirstResponder];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    NSString *searchText = searchBar.text;
    
    self.where = [NSString stringWithFormat:@"name LIKE '%%%@%%'", searchText];
    
    self.items = [Car SQPFetchAllWhere:self.where orderBy:self.orderProperty];
    
    [self.tableView reloadData];
}

-(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    
    if (self.orderLastIndex == selectedScope) {
        self.orderDirection = !self.orderDirection;
    }
    
    if (selectedScope == 0) {
        self.orderProperty = @"name";
    } else if (selectedScope == 1) {
        self.orderProperty = @"color";
    } else {
        self.orderProperty = @"power";
    }
    
    if (self.orderDirection == YES) {
        self.orderProperty = [NSString stringWithFormat:@"%@ DESC", self.orderProperty];
    }
    
    self.orderLastIndex = selectedScope;
    
    self.items = [Car SQPFetchAllWhere:self.where orderBy:self.orderProperty];
    
    [self.tableView reloadData];
}

#pragma mark - UITableView Datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.items count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellidentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellidentifier];
    }
    
    Car *item = (Car*)[self.items objectAtIndex:indexPath.row];
    
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.color;
    cell.imageView.image = [UIImage imageNamed:item.name];
    
    return cell;
}

@end
