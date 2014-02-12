//
//  MockedItem.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 14/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLAModelProtocols.h"

@interface MockedItem : NSObject <CLAItem>

@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSNumber *identifier;
@property (nonatomic) NSString *type;
@property (nonatomic) id <CLATopic> topic;
@property (nonatomic, readonly) UIImage *mainImage;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSSet *images;
@property (nonatomic) NSString *eMailAddress;
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) NSString *detailText;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *zipcode;
@property (nonatomic) NSString *city;
@property (nonatomic) NSNumber *isEvent;

@property (nonatomic) NSNumber *ordering;

@end
