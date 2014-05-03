//
//  Item.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import "CLAModelProtocols.h"
#import "Topic.h"
#import "NSManagedObject+Commons.h"


@interface Item : NSManagedObject <CLAItem, MKAnnotation>

@property (nonatomic, copy) NSString * title;
@property (nonatomic, readonly) UIImage *mainImage;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSString *eMailAddress;
@property (nonatomic, retain) NSString *phoneNumber;
@property (nonatomic, retain) NSString *urlAddress;
@property (nonatomic, retain) NSString *detailText;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *zipcode;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *subType;
@property (nonatomic, weak) UIImage *pinMap;
@property (nonatomic, retain) NSData *pinMapData;
@property (nonatomic, retain) NSDate *date;


#pragma mark Relationships

@property (nonatomic, retain) Topic *topic;
@property (nonatomic, retain) NSSet *images;


-(void)generatePinMapFromMainImage;
-(id <CLAImage>)mainImageObject;

@end
