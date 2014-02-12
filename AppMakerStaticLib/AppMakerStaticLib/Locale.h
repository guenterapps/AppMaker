//
//  Locale.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 03/02/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CLAModelProtocols.h"

@interface Locale : NSManagedObject <CLALocale>

@property (nonatomic, retain) NSString * languageCode;
@property (nonatomic, retain) NSString * languageDescription;
@property (nonatomic, retain) NSNumber *ordering;

@end
