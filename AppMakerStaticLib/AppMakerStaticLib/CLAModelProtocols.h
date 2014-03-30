//
//  CLAItemProtocol.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 29/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol CLATopic;

@class UIImage, CLLocation;

@protocol CommonProperties <NSObject>

@property (nonatomic) NSDate *lastUpdated;
@property (nonatomic) NSDate *created;
@property (nonatomic) NSNumber *ordering;

@end

@protocol CLAItem <CommonProperties>

@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSString *identifier;
@property (nonatomic) id <CLATopic> topic;
@property (nonatomic, readonly) UIImage *mainImage;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSSet *images;
@property (nonatomic) NSString *eMailAddress;
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) NSString *urlAddress;
@property (nonatomic) NSString *detailText;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *zipcode;
@property (nonatomic) NSString *city;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *subType;
@property (nonatomic) UIImage *pinMap;
@property (nonatomic) NSDate *date;

@end

@protocol CLATopic <CommonProperties>

@property (nonatomic) NSString *topicCode;
@property (nonatomic) NSString *title;
@property (nonatomic) NSSet *items;
@property (nonatomic) NSString *sortOrder;

@end

@protocol CLAImage <CommonProperties>

@property (nonatomic) NSNumber *primary;
@property (nonatomic) UIImage *image;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *imageURL;
@property (nonatomic) NSString *videoURL;
@property (nonatomic) NSString *fileName;
@property (nonatomic) id <CLAItem> item;

@end

@protocol CLALocale <NSObject>

@property (nonatomic) NSString *languageCode;
@property (nonatomic) NSString *languageDescription;

@end
