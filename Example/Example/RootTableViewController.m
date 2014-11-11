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
#import "TestObject.h"

#import "limits.h"

@interface RootTableViewController ()
- (void)getFlickRandomPhoto;
- (Car*)getRandomCar;
- (void)otherExamples;
- (void)testSQLiteTypes;
- (void)testTransactions;
- (BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2;
@end

@implementation RootTableViewController {
    User *_userJohn;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Log all SQL requests :
    [SQPDatabase sharedInstance].logRequests = YES;
    
    // Log all properties scanned :
    [SQPDatabase sharedInstance].logPropertyScan = YES;
    
    // Create Database :
    [[SQPDatabase sharedInstance] setupDatabaseWithName:@"SQPersist.db"];
    
    // Check if table missing a property. If yes add automaticatly the associated column into the table :
    [SQPDatabase sharedInstance].addMissingColumns = YES;
    
    NSLog(@"DB path: %@ ", [[SQPDatabase sharedInstance] getDdPath]);
    
    [self otherExamples];
    
    self.items = [Car SQPFetchAll];
    
    // Test all properties types :
    [self testSQLiteTypes];

    // JSON Response exemple :
    [self getFlickRandomPhoto];
    
    // Test transactions :
    [self testTransactions];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Example

- (void)testTransactions {
    
    // Commit :
    
    [[SQPDatabase sharedInstance] beginTransaction];
    
    TestObject *testObject = [TestObject SQPCreateEntity];
    testObject.testString = @"Test transaction";
    
    [testObject SQPSaveEntity];
    
    [[SQPDatabase sharedInstance] commitTransaction];

    // Rollback :
    
    [[SQPDatabase sharedInstance] beginTransaction];
    
    testObject.testString = @"Test Rollabck";
    
    [testObject SQPSaveEntity];
    
    [[SQPDatabase sharedInstance] rollbackTransaction];
    
    TestObject *testFinal = [TestObject SQPFetchOneByID:testObject.objectID];
    
    NSLog(@"testObject.testString: %@", testFinal.testString);
    
    NSLog(@"testObject.testNumber: %@ (default value)", testFinal.testNumber);
}

- (void)testSQLiteTypes {
    
    NSString *text = @"Objective-C Persistence framework wrapper around SQLite";
    
    TestObject *testObject = [TestObject SQPCreateEntity];
    testObject.testString = text; // NSString -> become TEXT into SQLite database
    testObject.testNumber = [NSNumber numberWithFloat:FLT_MAX] ; // NSNumber -> become REAL into SQLite database
    testObject.testDecimalNumber = [NSDecimalNumber decimalNumberWithString:@"3467374639467936.3746374639"]; // NSDecimalNumber -> become REAL into SQLite database
    testObject.testDate = [NSDate date]; // NSDate -> become INTEGER into SQLite database (Timestamp Since 1970)
    testObject.testData = [text dataUsingEncoding:NSUTF8StringEncoding];; // NSData -> become BLOB into SQLite database
    testObject.testImage = [UIImage imageNamed:@"Icon-Test.png"]; // UIImage -> become BLOB into SQLite database
    testObject.testURL = [NSURL URLWithString:@"https://github.com/christopherney/SQPersist"]; // NSURL -> become TEXT into SQLite database
    testObject.testInt = INT32_MAX; // int -> become INTEGER into SQLite database
    testObject.testDouble = DBL_MAX; // double -> become REAL into SQLite database
    testObject.testLong = LDBL_MAX; // long -> become REAL into SQLite database
    testObject.testLongLong = LDBL_MAX; // long long -> become REAL into SQLite database
    testObject.testShort = INT16_MAX; // short -> become INTEGER into SQLite database
    testObject.testFloat = FLT_MAX; // float -> become REAL into SQLite database
    testObject.testBool = YES; // BOOL -> become INTEGER into SQLite database
    
    [testObject SQPSaveEntity];
    
    TestObject *testResult = [TestObject SQPFetchOneByID:testObject.objectID];
    
    if ([testResult.testString isEqualToString:testObject.testString]) {
        NSLog(@"NSString OK - (%@)", testResult.testString);
    } else {
        NSLog(@"NSString KO!");
    }
    
    if ([testResult.testNumber isEqualToNumber:testObject.testNumber]) {
        NSLog(@"NSNumber OK - (%@)", testResult.testNumber);
    } else {
        NSLog(@"NSNumber KO!");
    }
    
    if ([testResult.testDecimalNumber isEqualToNumber:testObject.testDecimalNumber]) {
        NSLog(@"NSDecimalNumber OK - (%@)", testResult.testDecimalNumber);
    } else {
        NSLog(@"NSDecimalNumber KO!");
    }
    
    if ([[testResult.testDate description] isEqualToString:[testObject.testDate description]]) {
        NSLog(@"NSDate OK - (%@)", testResult.testDate);
    } else {
        NSLog(@"NSDate KO! %@ != %@", testObject.testDate, testResult.testDate);
    }

    if ([testResult.testData isEqualToData:testObject.testData]) {
        NSLog(@"NSData OK - (%lu)", (unsigned long)testResult.testData.length);
    } else {
        NSLog(@"NSData KO!");
    }

    if (CGSizeEqualToSize(testResult.testImage.size, testObject.testImage.size)) {
        NSLog(@"UIImage OK - (width: %f, height: %f)", testResult.testImage.size.width, testResult.testImage.size.height);
    } else {
        NSLog(@"UIImage KO!- (width: %f, height: %f) != (width: %f, height: %f)", testResult.testImage.size.width, testResult.testImage.size.height, testObject.testImage.size.width, testObject.testImage.size.height);
    }
    
    if ([testResult.testURL isEqual:testObject.testURL]) {
        NSLog(@"NSURL OK - (%@)", [testResult.testURL absoluteString]);
    } else {
        NSLog(@"NSURL KO!");
    }
    
    if (testResult.testInt == testObject.testInt) {
        NSLog(@"int OK - (%d)", testResult.testInt);
    } else {
        NSLog(@"int KO!");
    }
    
    if (testResult.testDouble == testObject.testDouble) {
        NSLog(@"double OK - (%f)", testResult.testDouble);
    } else {
        NSLog(@"double KO!");
    }
    
    if (testResult.testLong == testObject.testLong) {
        NSLog(@"long OK - (%ld)", testResult.testLong);
    } else {
        NSLog(@"long KO!");
    }
    
    if (testResult.testLongLong == testObject.testLongLong) {
        NSLog(@"long long OK - (%lld)", testResult.testLongLong);
    } else {
        NSLog(@"long long KO!");
    }
    
    if (testResult.testShort == testObject.testShort) {
        NSLog(@"short OK - (%d)", testResult.testShort);
    } else {
        NSLog(@"short KO!");
    }
    
    if (testResult.testFloat == testObject.testFloat) {
        NSLog(@"float OK - (%f)", testResult.testFloat);
    } else {
        NSLog(@"float KO!");
    }
    
    if (testResult.testBool == testObject.testBool) {
        NSLog(@"BOOL OK - (%hhd)", testResult.testBool);
    } else {
        NSLog(@"BOOL KO!");
    }
    
    // Convertion to Dictionary (for JSON request for example) :
    NSMutableDictionary *dictionary = [testResult toDictionary];
    NSLog(@"Dicionary : %@", [dictionary description]);
    
    // Clear test table :
    [TestObject SQPTruncateAll];
}

- (BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2
{
    NSData *data1 = UIImagePNGRepresentation(image1);
    NSData *data2 = UIImagePNGRepresentation(image2);
    
    return [data1 isEqual:data2];
}

- (void)otherExamples {
    
    [[SQPDatabase sharedInstance] beginTransaction];
    
    // Create Table at the first init (if tbale ne exists) :
    _userJohn = [User SQPCreateEntity];
    _userJohn.firstName = @"John";
    _userJohn.lastName = @"McClane";
    _userJohn.birthday = [NSDate date];
    _userJohn.photo = [UIImage imageNamed:@"Photo"];
    
    // INSERT Object :
    [_userJohn SQPSaveEntity];
    
    // SELECT BY objectID (John McClane) :
    User *userSelected = [User SQPFetchOneByID:_userJohn.objectID];
    userSelected.amount = 139203000.50f;
    
    // UPDATE Object :
    [userSelected SQPSaveEntity];
    
    User *friendJohn = [User SQPCreateEntity];
    friendJohn.firstName = @"Hans";
    friendJohn.lastName = @"Gruber";
    
    _userJohn.friends = [[NSMutableArray alloc] initWithObjects:friendJohn, nil];
    
    // UPDATE Object :
    [_userJohn SQPSaveEntity];
    
    User *userJohn2 = [User SQPFetchOneWhere:@"lastname = 'McClane'"];
    userJohn2.myCar = [self getRandomCar];
    
    [userJohn2 SQPSaveEntity];
    
    NSLog(@"Name user : %@", userJohn2.firstName);
    
    Car *car1 = [self getRandomCar];
    car1.owner = _userJohn;
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
    
    for (Car *car in cars) {
        
        if (car.owner != nil) {
            NSLog(@"Car's owner : %@ %@", car.owner.firstName, car.owner.lastName);
        }
    }
    
    [[SQPDatabase sharedInstance] commitTransaction];
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
                
                [flickrItem populateWithDictionary:item];
                
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
    car.owner = _userJohn;
    car.power = [[powers objectAtIndex:randomIndexPower] intValue];
    car.urlLogo = [NSURL URLWithString:@"https://github.com/christopherney/SQPersist"];
    
    return car;
}

#pragma mark - Actions

- (IBAction)actionRemoveDatabase:(id)sender {
    
    // If database exists:
    if ([[SQPDatabase sharedInstance] databaseExists]) {
        
        // REMOVE Local Database :
        [[SQPDatabase sharedInstance] removeDatabase];
        
        NSLog(@"DB '%@' removed!", [[SQPDatabase sharedInstance] getDdName]);
        
        self.items = nil;
        
        [self.tableView reloadData];
    }
}

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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %d horses", item.color, item.power];
    cell.imageView.image = [UIImage imageNamed:item.name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        Car *item = (Car*)[self.items objectAtIndex:indexPath.row];
        
        if ([item SQPDeleteEntity]) {
            
            [self.items removeObjectAtIndex:indexPath.row];
            
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        }
    }
}

@end
