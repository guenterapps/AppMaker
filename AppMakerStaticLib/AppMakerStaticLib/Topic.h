//
//  Topic.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CLAModelProtocols.h"

@class Item;

@interface Topic : NSManagedObject <CLATopic>

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *items;
@property (nonatomic, retain) NSString *topicCode;
@property (nonatomic, retain) NSString *sortOrder;
@end

@interface Topic (CoreDataGeneratedAccessors)

- (void)addItemsObject:(Item *)value;
- (void)removeItemsObject:(Item *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
