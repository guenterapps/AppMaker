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


extern NSString *const CLAAppDataStoreUIBackgroundColorKey;

extern NSString *const CLAAppDataStoreUICellShadowColorKey;

extern NSString *const CLAAppDataStoreUIFontNameKey;
extern NSString *const CLAAppDataStoreUIFontColorKey;

extern NSString *const CLAAppDataStoreUIBoxFontInterlineKey;
extern NSString *const CLAAppDataStoreUIBoxColorKey;
extern NSString *const CLAAppDataStoreUIBoxDescriptionFontKey;
extern NSString *const CLAAppDataStoreUIBoxFontColorKey;
extern NSString *const CLAAppDataStoreUIBoxFontSizeKey;

extern NSString *const CLAAppDataStoreUIHeaderColorKey;
extern NSString *const CLAAppDataStoreUIHeaderFontColorKey;
extern NSString *const CLAAppDataStoreUIHeaderFontSizeKey;

extern NSString *const CLAAppDataStoreUIMenuFontColorKey;
extern NSString *const CLAAppDataStoreUIMenuFontSizeKey;
extern NSString *const CLAAppDataStoreUIMenuBackgroundColorKey;
extern NSString *const CLAAppDataStoreUIMenuSelectedColorKey;

extern NSString *const CLAAppDataStoreUIMapIconKey;
extern NSString *const CLAAppDataStoreUIMenuIconKey;

extern NSString *const CLAAppDataStoreUIMainListFontColorKey;
extern NSString *const CLAAppDataStoreUIMainListFontSizeKey;
extern NSString *const CLAAppDataStoreUIBackIconKey;
extern NSString *const CLAAppDataStoreUIListIconKey;
extern NSString *const CLAAppDataStoreUIShareIconKey;

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

-(void)fetchRemoteDataWithTimeout:(NSTimeInterval)timeout;
-(void)fetchRemoteDataForSingleContent:(NSString *)contentId withTimeout:(NSTimeInterval)timeout;

-(void)save:(NSError **)error;

#pragma mark - Image Fetching

-(void)fetchMainImagesWithCompletionBlock:(void (^)(NSError *))block;
-(void)asyncFetchMainImagesWithCompletionBlock:(void (^)(NSError *))block;

-(void)fetchMainImagesForTopic:(id <CLATopic>)topic completion:(void (^)(NSError *))block;
-(void)fetchImagesForImageObjects:(NSArray *)items completion:(void (^)(NSError *))block;
																
//-(void)fetchImageForImageObject:(Image *)image completion:(void (^)(NSError *, NSData *))block;

-(void)invalidateCache;



@end
