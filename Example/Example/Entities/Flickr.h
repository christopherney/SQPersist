//
//  Flickr.h
//  Example
//
//  Created by Christopher Ney on 02/11/2014.
//  Copyright (c) 2014 Christopher Ney. All rights reserved.
//

#import "SQPObject.h"

@interface Flickr : SQPObject

@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *descriptionPhoto;
@property (nonatomic, strong) NSURL *link;
@property (nonatomic, strong) NSURL *photoURL;
@property (nonatomic, strong) NSString *title;

@end
