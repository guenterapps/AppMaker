//
//  Images.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+Commons.h"
#import "CLAModelProtocols.h"
#import "Item.h"

@interface Image : NSManagedObject <CLAImage>

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) Item *item;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *imageURL;
@property (nonatomic) NSString *videoURL;
@property (nonatomic) NSString *fileName;
@property (nonatomic) NSNumber *primary;
@property (nonatomic) NSDate *lastUpdated;

@end
