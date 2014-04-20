//
//  CLAAppDataStore.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 29/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLAModelProtocols.h"
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "CLAFetchManager.h"
#import "CLAFetchManagerDelegate.h"
#import "CLAAppDataStoreUIComponentKeys.h"

@class AppMaker, Image, CLAPreferences;

/**
 *  Notification keys
 */

extern NSString *const CLAAppDataStoreWillFetchImages;
extern NSString *const CLAAppDataStoreDidFetchImage;
extern NSString *const CLATotalImagesToFetchKey;

extern NSString *const CLAAppDataStoreDidStartToFetchNewData;
extern NSString *const CLAAppDataStoreDidFetchNewData;
extern NSString *const CLAAppDataStoreDidFailToFetchNewData;
extern NSString *const CLAAppDataStoreDidStopSeachingPosition;

extern NSString *const CLAAppDataStoreDidInvalidateCache;

extern NSString *const CLALastSyncDateKey;
extern NSString *const CLALastPositionLatitudeKey;
extern NSString *const CLALastPositionLongitudeKey;

extern NSString *const CLAAppDataStoreFetchErrorKey;

@class CLLocation;

@interface CLAAppDataStore : NSObject <CLLocationManagerDelegate, CLAFetchManagerDelegate>

#pragma mark - Core Data Stack

@property (nonatomic, readonly) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, readonly) NSManagedObjectContext *context;
@property (nonatomic, readonly) NSManagedObjectModel *model;

#pragma mark - Store Properties & Methods

@property (nonatomic, readonly) NSDate *lastSyncDate;
@property (nonatomic, readonly) CLLocation *lastPosition;
@property (nonatomic) CLLocation *defaultPosition;
@property (nonatomic) AppMaker *appMaker;
@property (nonatomic) NSTimeInterval cacheTimeout;

@property (nonatomic) CLAPreferences *preferences;

-(void)startUpdatingLocation;

-(id <CLAItem>)contentWithIdentifier:(NSString *)identifier;
-(NSArray *)contents;
-(NSArray *)contentsForTopic:(id <CLATopic>)topic;
-(NSArray *)pois;
-(NSArray *)poisForTopic:(id <CLATopic>)topic;
-(NSArray *)topics;
-(NSArray *)locales;

-(NSDictionary *)userInterface;

-(void)preFetchData;

-(void)fetchRemoteDataWithTimeout:(NSTimeInterval)timeout skipCaching:(BOOL)skip;
-(void)fetchRemoteDataForSingleContent:(NSString *)contentId withTimeout:(NSTimeInterval)timeout;

-(void)save:(NSError **)error;

#pragma mark - Image Fetching

-(void)skipImageLoading;

-(void)fetchMainImageForItem:(id<CLAItem>)item completionBlock:(void (^)(NSError *))block;
-(void)fetchMainImagesWithCompletionBlock:(void (^)(NSError *))block;
-(void)preFetchMainImagesWithCompletionBlock:(void (^)(NSError *))block;

-(void)fetchImagesForImageObjects:(NSArray *)items completion:(void (^)(NSError *))block;


-(void)invalidateCache;



@end
