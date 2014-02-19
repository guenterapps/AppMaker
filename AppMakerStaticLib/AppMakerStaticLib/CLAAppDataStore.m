//
//  CLAAppDataStore.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 29/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAAppDataStore.h"
#import "AppMaker.h"
#import "CLAImageFetch.h"
#import "Image.h"
#import "Item.h"
#import "UIColor-Expanded.h"

#ifdef DEBUG

#import "CLAAppDataStore+FakeData.h"

#endif

NSString *const CLAAppDataStoreWillFetchImages			= @"CLAAppDataStoreWillFetchImages";
NSString *const CLAAppDataStoreDidFetchImage			= @"CLAAppDataStoreDidFetchImage";
NSString *const CLATotalImagesToFetchKey				= @"CLATotalImagesToFetchKey";

NSString *const CLAAppDataStoreDidStartToFetchNewData	= @"CLAAppDataStoreDidStartToFetchNewData";
NSString *const CLAAppDataStoreDidFetchNewData			= @"CLAAppDataStoreDidFetchNewData";
NSString *const CLAAppDataStoreDidFailToFetchNewData	= @"CLAAppDataStoreDidFailToFetchNewData";
NSString *const CLAAppDataStoreDidStopSeachingPosition	= @"CLAAppDataStoreDidStopSeachingPosition";

NSString *const CLAAppDataStoreDidInvalidateCache		= @"CLAAppDataStoreDidInvalidateCache";

NSString *const CLALastSyncDateKey						= @"CLALastSyncDateKey";
NSString *const CLALastPositionLatitudeKey				= @"CLALastPositionLatitudeKey";
NSString *const CLALastPositionLongitudeKey				= @"CLALastPositionLongitudeKey";
NSString *const CLAAppDataStoreFetchErrorKey			= @"CLAAppDataStoreFetchErrorKey";

NSString *const CLAAppDataStoreUIBackgroundColorKey		= @"CLAAppDataStoreUIBackgroundColorKey";
NSString *const CLAAppDataStoreUIHeaderColorKey			= @"CLAAppDataStoreUIHeaderColorKey";
NSString *const CLAAppDataStoreUIFontNameKey			= @"CLAAppDataStoreUIFontNameKey";
NSString *const CLAAppDataStoreUIFontColorKey			= @"CLAAppDataStoreUIFontColorKey";
NSString *const CLAAppDataStoreUIHeaderFontColorKey		= @"CLAAppDataStoreUIHeaderFontColorKey";
NSString *const CLAAppDataStoreUIHeaderFontSizeKey		= @"CLAAppDataStoreUIHeaderFontSizeKey";

NSString *const CLAAppDataStoreUIBoxFontInterlineKey	= @"CLAAppDataStoreUIBoxFontInterlineKey";
NSString *const CLAAppDataStoreUIBoxColorKey			= @"CLAAppDataStoreUIBoxColorKey";
NSString *const CLAAppDataStoreUIBoxFontColorKey		= @"CLAAppDataStoreUIBoxFontColorKey";
NSString *const CLAAppDataStoreUIBoxFontSizeKey			= @"CLAAppDataStoreUIBoxFontSizeKey";
NSString *const CLAAppDataStoreUIBoxDescriptionFontKey	= @"CLAAppDataStoreUIBoxDescriptionFontKey";

NSString *const CLAAppDataStoreUIMenuFontColorKey		= @"CLAAppDataStoreUIMenuFontColorKey";
NSString *const CLAAppDataStoreUIMenuFontSizeKey		= @"CLAAppDataStoreUIMenuFontSizeKey";
NSString *const CLAAppDataStoreUIMenuBackgroundColorKey = @"CLAAppDataStoreUIMenuBackgroundColorKey";
NSString *const CLAAppDataStoreUIMenuSelectedColorKey	= @"CLAAppDataStoreUIMenuSelectedColorKey";

NSString *const CLAAppDataStoreUIMainListFontColorKey	= @"CLAAppDataStoreUIMainListFontColorKey";
NSString *const CLAAppDataStoreUIMainListFontSizeKey	= @"CLAAppDataStoreUIMainListFontSizeKey";

NSString *const CLAAppDataStoreUIMapIconKey				= @"CLAAppDataStoreUIIconMapKey";
NSString *const CLAAppDataStoreUIMenuIconKey			= @"CLAAppDataStoreUIIconMenuKey";
NSString *const CLAAppDataStoreUIBackIconKey			= @"CLAAppDataStoreUIIconBackKey";
NSString *const CLAAppDataStoreUIListIconKey			= @"CLAAppDataStoreUIListIconKey";
NSString *const CLAAppDataStoreUIShareIconKey			= @"CLAAppDataStoreUIShareIconKey";


@interface CLAAppDataStore ()
{
	NSOperationQueue *_queue;
	NSArray *_contents;
	NSArray *_topics;
	NSArray *_locales;
	
	NSMutableSet *_imageLoadRequestIds;
	
	NSPredicate *_poisPredicate;
}

-(NSArray *)fetchObjectsInEntity:(NSString *)entity;

-(NSOperationQueue *)operationQueue;

-(void)mergeObjects:(NSNotification *)notification;

-(void)fetchMainImagesForItems:(NSArray *)items dispatch:(void (*)())dispatch completion:(void (^)(NSError *))block;

@property (nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) NSDate *lastSyncDate;
@property (nonatomic) CLLocation *lastPosition;

@end

@implementation CLAAppDataStore

@synthesize context = _context, model = _model, coordinator = _coordinator, lastSyncDate = _lastSyncDate, lastPosition = _lastPosition, userDefaults = _userDefaults, locationManager = _locationManager, cacheTimeout = _cacheTimeout;


-(id)init
{
	if (self = [super init])
	{
		
#ifdef LOAD_FAKE_DATA
	#ifndef LIB_UNIT_TEST
		[self setupFakeData];
	#endif
#endif
		_imageLoadRequestIds = [[NSMutableSet alloc] init];
		_poisPredicate = [NSPredicate predicateWithFormat:@"latitude > 0 AND longitude > 0"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mergeObjects:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:nil];
		
	}
	
	return self;
}

#pragma mark - Core Methods

-(void)startUpdatingLocation
{
	if ([CLLocationManager locationServicesEnabled])
	{
		NSAssert(self.locationManager, @"Should have a CLLocationManager now!\n");
		
		NSLog(@"Starting updating location...\n");

		self.locationManager.delegate = self;
		self.locationManager.distanceFilter = 500.0;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
		[self.locationManager startUpdatingLocation];
	}
}

-(void)save:(NSError **)error
{
	if ([self.context hasChanges])
	{
		__block NSError *internalError;
		
		[self.context performBlockAndWait:^()
		{
			[self.context save:&internalError];
			
			if (internalError && error)
			{
				NSLog(@"Error saving: %@", [internalError localizedDescription]);
				*error = internalError;
			}

		}];
	}
}

#pragma mark - CLLocationManager delegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	NSLog(@"Changed CLLocationManager authorization status to %i\n", status);
	
	if (status == kCLAuthorizationStatusAuthorized)
	{
		[self.locationManager startUpdatingLocation];
	}
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"An error occurred retrieving location: %@\n", error);
	
//	if (kCLErrorDenied == [error code])
//	{
		[self.locationManager stopUpdatingLocation];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidStopSeachingPosition object:self];
//	}
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	CLLocation *newLocation = [locations lastObject];
	
	if (newLocation.horizontalAccuracy < 0)
	{
		return;
	}
	
	if (ABS([newLocation.timestamp timeIntervalSinceNow]) < 30.0)
	{
		NSLog(@"Found location: latitude %+.6f, longitude %+.6f\n", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
		
		NSNumber *latitude	= [NSNumber numberWithDouble:newLocation.coordinate.latitude];
		NSNumber *longitude = [NSNumber numberWithDouble:newLocation.coordinate.longitude];
		
		[self.userDefaults setObject:latitude forKey:CLALastPositionLatitudeKey];
		[self.userDefaults setObject:longitude forKey:CLALastPositionLongitudeKey];
		
		[self.locationManager stopUpdatingLocation];
	
		[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidStopSeachingPosition object:self];
	}
}


#pragma mark - Data Fetch

#pragma mark Remote data

- (void)fetchImagesForObjects:(NSMutableArray *)objectIDs urls:(NSMutableArray *)urls block:(void (^)(NSError *))block
{
	__block NSError *error;
	NSInteger imagesToFetch = [objectIDs count];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	
	dispatch_apply(imagesToFetch, queue, ^(size_t iteration)
	{
		NSInteger index = (NSInteger)iteration;

#ifdef DEBUG
		NSLog(@"Fetching image at url: %@", urls[index]);
#endif

		NSError *internalError;
		NSURL *url			= [NSURL URLWithString:urls[index]];
		NSData *imageData	= [NSData dataWithContentsOfURL:url options:0 error:&internalError];

		if (internalError)
		{
			error = internalError;
			NSLog(@"%@", internalError);
		}

		dispatch_async(dispatch_get_main_queue(), ^()
		{
			if (!internalError)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidFetchImage object:self userInfo:nil];
			}

			Item *item = (Item *)[self.context objectWithID:objectIDs[index]];

			[(NSManagedObject *)[item mainImageObject] setValue:imageData forKey:@"imageData"];

			[item generatePinMapFromMainImage];
		});

	});

	dispatch_async(dispatch_get_main_queue(), ^()
	{
		NSError *saveError;

		[self save:&saveError];
		
		if (saveError)
		{
			NSLog(@"Error saving after fetching images: %@", saveError);
			abort();
		}
		
		[self invalidateCache];

		block(error);

	});

}

-(void)fetchMainImagesForItems:(NSArray *)items dispatch:(void (*)())dispatch completion:(void (^)(NSError *))block
{
	NSMutableArray *objectIDs	= [NSMutableArray array];
	NSMutableArray *urls		= [NSMutableArray array];
	
	if (([items count]) > 0)
	{
		for (Item *item in items)
		{
			id <CLAImage> mainImage = [item mainImageObject];
			
			if (![mainImage imageURL])
			{
				continue;
			}
			
			[objectIDs	addObject:[item objectID]];
			[urls		addObject:[(id <CLAImage>)mainImage imageURL]];
		}

		dispatch_async(dispatch_get_main_queue(), ^()
					   {
						   NSDictionary *userInfo = @{CLATotalImagesToFetchKey : @([urls count])};
						   
						   [[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreWillFetchImages object:self userInfo:userInfo];
					   });
	
		dispatch(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^()
		{
			[self fetchImagesForObjects:objectIDs urls:urls block:block];

		});
	}
	else
	{
		NSLog(@"Requested to fetch images for empty array!");
		dispatch_async(dispatch_get_main_queue(), ^()
					   {
						   NSDictionary *userInfo = @{CLATotalImagesToFetchKey : @(0)};
						   
						   [[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreWillFetchImages object:self userInfo:userInfo];
					   });
		block(nil);
	}

}

-(void)asyncFetchMainImagesWithCompletionBlock:(void (^)(NSError *))block
{
	static NSPredicate *nilImages;
	
	if (!nilImages)
	{
		nilImages = [NSPredicate predicateWithFormat:@"%K == nil", @"mainImage"];
	}
	
	NSMutableArray *items = [NSMutableArray array];
	
	for (Topic *topic in self.topics)
	{
		[items addObjectsFromArray:[[[topic items] allObjects] filteredArrayUsingPredicate:nilImages]];
	}
	
	void (*dispatch)(dispatch_queue_t, dispatch_block_t) = &dispatch_async;
	
	[self fetchMainImagesForItems:items dispatch:dispatch completion:block];
}

-(void)fetchMainImagesWithCompletionBlock:(void (^)(NSError *))block
{
	static NSPredicate *nilImages;
	
	if (!nilImages)
	{
		nilImages = [NSPredicate predicateWithFormat:@"%K == nil", @"mainImage"];
	}

	NSMutableArray *items = [NSMutableArray array];

	for (Topic *topic in self.topics)
	{
		[items addObjectsFromArray:[[[topic items] allObjects] filteredArrayUsingPredicate:nilImages]];
	}
	
	void (*dispatch)(dispatch_queue_t, dispatch_block_t) = &dispatch_sync;
	
	[self fetchMainImagesForItems:items dispatch:dispatch completion:block];

}

//-(void)fetchMainImagesForTopic:(id <CLATopic>)topic completion:(void (^)(NSError *))block
//{
//	static NSPredicate *nilImages;
//	
//	if (!nilImages)
//	{
//		nilImages = [NSPredicate predicateWithFormat:@"%K == nil", @"mainImage"];
//	}
//	
//	NSMutableArray *objectIDs	= [NSMutableArray array];
//	NSMutableArray *urls		= [NSMutableArray array];
//	NSSet *items				= [[topic items] filteredSetUsingPredicate:nilImages];
//	
//	__block NSError *error;
//	
//	if (([items count]) > 0)
//	{
//		for (Item *item in items)
//		{
//			id <CLAImage> mainImage = [item mainImageObject];
//			
//			if (![mainImage imageURL])
//			{
//				continue;
//			}
//
//			[objectIDs	addObject:[item objectID]];
//			[urls		addObject:[(id <CLAImage>)mainImage imageURL]];
//		}
//		
//		NSInteger imagesToFetch = [objectIDs count];
//
//
//		dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^()
//		{
//
//			dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
//			
//			dispatch_apply(imagesToFetch, queue, ^(size_t iteration)
//			{
//				NSInteger index = (NSInteger)iteration;
//
//#ifdef DEBUG
//				NSLog(@"Fetching image at url: %@", urls[index]);
//#endif
//				
//				NSError *internalError;
//				NSURL *url			= [NSURL URLWithString:urls[index]];
//				NSData *imageData	= [NSData dataWithContentsOfURL:url options:0 error:&internalError];
//				
//				if (internalError)
//				{
//					error = internalError;
//					NSLog(@"%@", internalError);
//				}
//				
//				Item *item = (Item *)[self.context objectWithID:objectIDs[index]];
//					
//				[(NSManagedObject *)[item mainImageObject] setValue:imageData forKey:@"imageData"];
//					
//				[item generatePinMapFromMainImage];
//			});
//			
//			block(error);
//
//		});
//	}
//}

-(void)fetchImagesForImageObjects:(NSArray *)items completion:(void (^)(NSError *))block
{
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^()
	{
		__block NSError *error;
		
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
		
		dispatch_apply([items count], queue, ^(size_t iteration)
		{
			NSError *internalError;
			NSInteger index = (NSInteger)iteration;
			
			Image *item = (Image *)[self.context objectWithID:items[index]];
			
			NSURL *url			= [NSURL URLWithString:[item imageURL]];
			NSData *imageData	= [NSData dataWithContentsOfURL:url options:0 error:&internalError];
			
#ifdef DEBUG
			NSLog(@"Fetching image at url: %@", [url absoluteString]);
#endif
			
			if (internalError)
			{
				error = internalError;
				NSLog(@"%@", internalError);
			}
			
			item.imageData = imageData;
			
		});

		dispatch_async(dispatch_get_main_queue(), ^()
		{
			NSError *saveError;
			
			[self save:&saveError];
			
			if (saveError)
			{
				NSLog(@"Error saving after fetching images!");
				abort();
			}

			block(error);
		});
		
	});
	
}



//-(void)fetchMainImageForItem:(id<CLAItem>)item completionBlock:(void (^)(NSError *))block
//{
//
//	static NSPredicate *primary;
//	
//	if (!primary)
//	{
//		primary = [NSPredicate predicateWithFormat:@"%K == %@", @"primary", [NSNumber numberWithBool:YES]];
//	}
//	
//	Image *image = [[[item images] filteredSetUsingPredicate:primary] anyObject];
//#warning no image;
//	if (!image)
//	{
//		return;
//	}
//	
//	NSAssert(image, @"Item should have a primary image!");
//	
//	
//	[self fetchImageForImageObject:image completion:block];
//
//}



-(void)fetchRemoteDataForSingleContent:(NSString *)contentId withTimeout:(NSTimeInterval)timeout
{
	NSOperationQueue *queue = [self operationQueue];

	CLAFetchManager *fetchManager = [[CLAFetchManager alloc] initWithEndpoint:self.appMaker.apiKey];
	
	fetchManager.singleContentId	= contentId;
	fetchManager.coordinator		= self.coordinator;
	fetchManager.delegate			= self;
	fetchManager.httpTimeout		= 0; //defaults to 30
	fetchManager.position			= self.lastPosition.coordinate;
	fetchManager.preferences		= self.preferences;
	
	[queue addOperation:fetchManager];
}

-(void)fetchRemoteDataWithTimeout:(NSTimeInterval)timeout
{

	NSDate *now = [NSDate date];
	
	if (ABS([self.lastSyncDate timeIntervalSinceDate:now]) < self.cacheTimeout)
	{
		double delayInSeconds = 1.0;

		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidFetchNewData object:self];
		});

		return;
	}

//	self.lastSyncDate = now; //moved to fetchManagerDidFinishFetchingData:
	
	NSOperationQueue *queue = [self operationQueue];
	
	CLAFetchManager *fetchManager = [[CLAFetchManager alloc] initWithEndpoint:self.appMaker.apiKey];

	fetchManager.coordinator	= self.coordinator;
	fetchManager.delegate		= self;
	fetchManager.httpTimeout	= 0; //defaults to 30
	fetchManager.position		= self.lastPosition.coordinate;
	fetchManager.preferences	= self.preferences;
	
	[queue addOperation:fetchManager];
}

#pragma mark CLAFetchManagerDelegate methods

-(void)fetchManagerdidStartFetchingData:(CLAFetchManager *)fetchMananager
{
	[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidStartToFetchNewData object:self];
}

-(void)fetchManagerDidFinishFetchingData:(CLAFetchManager *)fetchMananager
{
	
#ifdef DEBUG
	NSLog(@"FetchManager did get data successfully...");
#endif
	self.lastSyncDate = [NSDate date];
	
	[self invalidateCache];

	[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidFetchNewData object:self];
	
}

-(void)fetchMananager:(CLAFetchManager *)fetchMananager didFailWithError:(NSError *)error
{
	
#ifdef DEBUG
	NSLog(@"FetchManager did get error: %@", error);
#endif
	
	NSDictionary *userInfo;
	
	if (error)
	{
		userInfo = @{CLAAppDataStoreFetchErrorKey : error};
	}
	
	[self invalidateCache];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidFailToFetchNewData
														object:self
													  userInfo:userInfo];
}

#pragma mark Cached Data

-(void)invalidateCache
{
	_topics		= nil;
	_contents	= nil;
	_locales	= nil;
	
	[self.context reset];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CLAAppDataStoreDidInvalidateCache object:self];
}

-(void)preFetchData
{
#warning IMCOMPLETE
	
	NSLog(@"Prefetch Data...");
	/*
	 Needed to setup data store with cached data where the application starts.
	 In the case the connection fails or needs more time, the view controllers will find the cached
	 data ready.
	 */
	
}

-(NSDictionary *)userInterface
{
	static NSDictionary *userInterface;
	
	if (!userInterface)
	{
		/**
		 *  build userInterface dictionary from App supplied files:
		 *	- userInterfaceColors.plist
		 *	- userInterfaceImages.plist
		 *  - userInterfaceValues.plist
		 */
		
		__block NSMutableDictionary *temporaryDictionary = [NSMutableDictionary dictionary];
		
		NSArray *dictionaries = @[@"userInterfaceColors", @"userInterfaceImages", @"userInterfaceValues"];
				
		[dictionaries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		{
			NSString *dictionaryPath = [[NSBundle mainBundle] pathForResource:(NSString *)obj
																	   ofType:@"plist"];
			
			NSAssert(dictionaryPath, @"Could not load userInterface dictionary at path: %@", dictionaryPath);
			
			NSDictionary *currentDictionary = [NSDictionary dictionaryWithContentsOfFile:dictionaryPath];
			
			NSAssert(currentDictionary, @"Could not load dictionary at path: %@", currentDictionary);
			
			switch (idx)
			{
				case 0:
					for (NSString *key in currentDictionary)
					{
						UIColor *currentColor = [UIColor colorWithHexString:(NSString *)currentDictionary[key]];
						
						NSAssert(currentColor, @"Could not load color for key %@", key);
						
						[temporaryDictionary setValue:currentColor forKey:key];
					}
					break;
				case 1:
					for (NSString *key in currentDictionary)
					{
						UIImage *currentImage = [UIImage imageNamed:currentDictionary[key]];
						
						NSAssert(currentImage, @"Could not load image for key %@", key);
						
						[temporaryDictionary setValue:currentImage forKey:key];
					}
					break;
					
				default:
					
					[temporaryDictionary addEntriesFromDictionary:currentDictionary];
					
					break;
			}
			
			
		}];

		userInterface = [NSDictionary dictionaryWithDictionary:temporaryDictionary];
		
	}
	
	
	return userInterface;
}

-(NSArray *)locales
{
	if (!_locales)
	{
		_locales = [self fetchObjectsInEntity:@"Locale"];
	}
	
	return _locales;
}

-(NSArray *)topics
{
	if (!_topics)
	{
		_topics = [self fetchObjectsInEntity:@"Topic"];
		
		NSPredicate *_notEmptyTopics = [NSPredicate predicateWithFormat:@"items.@count > 0"];
		
		_topics = [_topics filteredArrayUsingPredicate:_notEmptyTopics];
	}
	
	return _topics;
}

-(id <CLAItem>)contentWithIdentifier:(NSString *)identifier
{
	if (!identifier)
	{
		return nil;
	}
	
	NSPredicate *contentPredicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
	
	return [[self.contents filteredArrayUsingPredicate:contentPredicate] lastObject];
}

-(NSArray *)contents
{
	if (!_contents)
	{
		_contents = [self fetchObjectsInEntity:@"Item"];
	}
	
	return _contents;
}

-(NSArray *)pois
{
	return [[self contents] filteredArrayUsingPredicate:_poisPredicate];
}

-(NSArray *)contentsForTopic:(id <CLATopic>)topic
{
	NSSortDescriptor *defaultOrdering = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
	
	return [[[topic items] allObjects] sortedArrayUsingDescriptors:@[defaultOrdering]];
}

-(NSArray *)poisForTopic:(id<CLATopic>)topic
{
	return [[self contentsForTopic:topic] filteredArrayUsingPredicate:_poisPredicate];
}

#pragma mark - Core Data Stack

-(NSManagedObjectModel *)model
{
	if (!_model)
	{
		NSString *path = [[NSBundle mainBundle] pathForResource:@"AppMaker"
														 ofType:@"momd"];
		
		NSURL *modelUrl = [NSURL fileURLWithPath:path];
		
		NSParameterAssert(modelUrl);
		
		_model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
		
		NSAssert(_model, @"could not load model");
	}
	
	return _model;
}

-(NSPersistentStoreCoordinator *)coordinator
{
	if (!_coordinator)
	{
		_coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
		
		NSAssert(_coordinator, @"Could not create NSPersistentStoreCoordinator!\n");
		
		NSURL * documentDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
																			inDomains:NSUserDomainMask] lastObject];
		
		
		NSURL *storeUrl = [documentDirectory URLByAppendingPathComponent:@"store.sqllite"];
		
		NSAssert(storeUrl, @"Could not load SQLite file!\n");
		
		NSError *error;
		
		NSPersistentStore *store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
															  configuration:nil
																		URL:storeUrl
																	options:nil
																	  error:&error];
		if (!store)
		{
			NSLog(@"%@\n", error);
			
			abort();
		}
	}
	
	return _coordinator;
}

-(NSManagedObjectContext *)context
{
	if (!_context)
	{
		_context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		
		
		[_context setPersistentStoreCoordinator:self.coordinator];
		

	}
	
	return _context;
}

#pragma mark - Properties


-(CLLocation *)lastPosition
{
	if (!_lastPosition)
	{
		NSNumber *latitude	= [[self userDefaults] objectForKey:CLALastPositionLatitudeKey];
		NSNumber *longitude	= [[self userDefaults] objectForKey:CLALastPositionLongitudeKey];
		
		if (!latitude || !longitude)
			_lastPosition = self.defaultPosition;
		else
		{
			_lastPosition = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
													   longitude:[longitude doubleValue]];
		}
		
	}
	
	return _lastPosition;
	
	
}

-(NSDate *)lastSyncDate
{
	if (!_lastSyncDate)
	{
		_lastSyncDate = [[self userDefaults] objectForKey:CLALastSyncDateKey];
	
		if (!_lastSyncDate)
			_lastSyncDate = [NSDate distantPast];
	}
	
	return _lastSyncDate;
}

-(void)setLastSyncDate:(NSDate *)lastSyncDate
{
	NSParameterAssert(lastSyncDate);
	
	[[self userDefaults] setObject:(_lastSyncDate = lastSyncDate)
											  forKey:CLALastSyncDateKey];
}

#pragma mark - private methods

//- (void)fetchImageURL:(NSURL *)imageURL completion:(void (^)(NSError *, NSData *, NSManagedObjectID *))block
//{
////	if ([_imageLoadRequestIds containsObject:image.objectID])
////		return;
////	
////	[_imageLoadRequestIds addObject:image.objectID];
////	
////	CLAImageFetch *imageFetch = [[CLAImageFetch alloc] initWithURL:[image imageURL]
////														 forObject:[image objectID]
////												   completionBlock:block];
////	imageFetch.coordinator = self.coordinator;
////	
////	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeObjects:) name:NSManagedObjectContextDidSaveNotification object:imageFetch];
////	
////	[[self operationQueue] addOperation:imageFetch];
//	
//	NSError *error;
//	NSData *imageData= [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
//	
//	block(error, imageData, );
//}

-(void)mergeObjects:(NSNotification *)notification
{

	if ([notification object] == self.context)
	{
		return;
	}
	
	[self.context performBlockAndWait:^()
	{
		[self.context mergeChangesFromContextDidSaveNotification:notification];
	}];

}

-(NSOperationQueue *)operationQueue
{
	if (!_queue)
	{
		_queue = [[NSOperationQueue alloc] init];
	}
	
	return _queue;
}

-(NSUserDefaults *)userDefaults
{
	if (!_userDefaults)
	{
		_userDefaults = [NSUserDefaults standardUserDefaults];
	}
	
	return _userDefaults;
}

-(CLLocationManager *)locationManager
{
	if (!_locationManager)
	{
		_locationManager = [[CLLocationManager alloc] init];
	}
	
	return _locationManager;
}

-(NSArray *)fetchObjectsInEntity:(NSString *)entity
{
	NSArray *items;
	NSError *error;
	
	NSFetchRequest *request		= [[NSFetchRequest alloc] initWithEntityName:entity];
	NSPredicate *hiddenFilter	= [NSPredicate predicateWithFormat:@"%K == %@", @"hidden", @NO];
	NSSortDescriptor *ascending = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
	
	[request setPredicate:hiddenFilter];
	[request setSortDescriptors:@[ascending]];
	
	request.fetchBatchSize = 10;
	
	if (!(items = [self.context executeFetchRequest:request error:&error]))
	{
		NSLog(@"%@\n", error);
		
		abort();
	}
	
	return items;
}

@end
