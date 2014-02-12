//
//  CLAImageFetch.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 15/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Used in notification, contains a dictionary of updated NSManagedObjectID's
 */

extern NSString *CLAUpdatedObjectIDsKey;

@class NSManagedObjectContext, NSPersistentStoreCoordinator, NSManagedObjectID;

@interface CLAImageFetch : NSOperation


@property (nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, readonly) NSManagedObjectContext *context;


@property (nonatomic) NSTimeInterval httpTimeout;

-(id)initWithURL:(NSString *)url forObject:(NSManagedObjectID *)objectId;
-(id)initWithURL:(NSString *)url forObject:(NSManagedObjectID *)objectId completionBlock:(void (^)(NSError *))block;

@end
