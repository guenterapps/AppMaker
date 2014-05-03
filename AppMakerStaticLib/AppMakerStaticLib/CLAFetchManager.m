//
//  CLAFetchManager.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 10/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "CLAFetchManager.h"
#import "CLADataParser.h"
#import "CLAModelProtocols.h"
#import "CLAPreferences.h"

#define CATEGORIES @"categories"
#define CATEGORY @"category"
#define CONTENTS @"generics"
#define SINGLECONTENT @"contents"
#define POSITION @"position"
#define LOCALES	@"locales"
#define LOCALE	@"locale"

static NSString *CLATopicEtagKey	= @"CLATopicEtagKey";
static NSString *CLAContentEtagKey	= @"CLAContentEtagKey";
static NSString *CLALocalesEtagKey	= @"CLALocalesEtagKey";

#define TIMEOUT	30

#define HTTP200OK 200
#define HTTP304OK 304

typedef BOOL (^ResponseHandler)(NSData *response);
typedef void (^CachedHandler)();
typedef NSArray * (^ParseHandler)(NSData *jsonData, NSError **error);

@interface CLAFetchManager ()
{
	NSOperationQueue *_notificationQueue;
	
	NSDictionary *_collectionEntities;
	
	BOOL _fetchSingleContent;
	NSString *_singleContentTopicCode;
	NSString *_languageCode;

}

@property (nonatomic) NSString *eTag;

-(NSOperationQueue *)notificationQueue;

-(BOOL)loadAndParseApiRequest:(NSString *)string eTagKey:(NSString *)key cachedHandler:(CachedHandler)cachedHandler completionHandler:(ResponseHandler)handler;

-(NSArray *)importJSON:(NSData *)jsonData parseBlock:(ParseHandler)block error:(NSError **)error;

-(void)setupManagerObjects;
-(void)switchData;

-(void)preLoadEntity:(NSString *)entity asCache:(BOOL)cached;

-(void)preLoadTopicsAsCache:(BOOL)cached;
-(void)preLoadContentsAsCache:(BOOL)cached;
-(void)preLoadMediasAsCache:(BOOL)cached;
-(void)preLoadLocalesAsCache:(BOOL)cached;

-(void)mergeObjects:(NSNotification *)notification;

/**
 *  Tells delegate and removes temporary data
 *
 *  @param error: Supplied error
 */

-(BOOL)quitWithError:(NSError *)error;

@end

@implementation CLAFetchManager

@synthesize context = _context, httpTimeout = _httpTimeout, singleContentId = _singleContentId;

-(id)initWithEndpoint:(NSString *)endPoint
{
	NSParameterAssert(endPoint);
	
	if (self = [super init])
	{
		_endpoint			= endPoint;
		
		
		_collectionEntities = @{@"Topic"	: @"_collectedTopics",
								@"Item"		: @"_collectedContents",
								@"Image"	: @"_collectedMedias",
								@"Locale"	: @"_collectedLocales"};
	}
	
	return self;
}

//-(id)initForTopic:(NSString *)topic withEndpoint:(NSString *)endPoint
//{
//	NSParameterAssert(topic && endPoint);
//
//	if (self = [super init])
//	{
//		_endpoint	= [endPoint copy];
//		_topic		= [topic copy];
//	}
//	
//	return self;
//}

-(NSTimeInterval)httpTimeout
{
	if (_httpTimeout)
	{
		_httpTimeout		= TIMEOUT;
	}
	
	return _httpTimeout;
}

-(void)setSingleContentId:(NSString *)singleContentId
{
//	NSParameterAssert(singleContentId);
	
	if ((_singleContentId = singleContentId))
		_fetchSingleContent = YES;;
}

#pragma mark - JSON Import

-(NSArray *)importLocalesJSON:(NSData *)jsonData error:(NSError *__autoreleasing *)error
{
	NSParameterAssert(jsonData);
	
	ParseHandler handler = ^NSArray *(NSData *data, NSError **err)
	{
		return [self.dataParser parseLocales:data error:err];
	};
	
	return [self importJSON:jsonData
				 parseBlock:handler
					  error:error];
}

-(NSArray *)importTopicsJSON:(NSData *)jsonData error:(NSError *__autoreleasing *)error
{
	NSParameterAssert(jsonData);
	
	ParseHandler handler = ^NSArray *(NSData *data, NSError **err)
	{
		return [self.dataParser parseTopics:jsonData error:err];
	};
	
	return [self importJSON:jsonData
				 parseBlock:handler
					  error:error];
}

-(NSArray *)importContentsJSON:(NSData *)jsonData error:(NSError *__autoreleasing *)error
{
	NSParameterAssert(jsonData);
	
	ParseHandler handler = ^NSArray *(NSData *data, NSError **err)
	{
		return [self.dataParser parseContents:data error:err];
	};
	
	return [self importJSON:jsonData
				 parseBlock:handler
					  error:error];
}

#pragma mark - Main

-(void)main
{

#ifdef LOAD_FAKE_DATA
	[self quitWithError:nil];
	return;
#endif

	NSParameterAssert(self.delegate);

	[self setupManagerObjects];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mergeObjects:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:nil];

	BOOL shouldContinue = YES;
	
	_languageCode = [self.preferences valueForKey:CLAPreferredLanguageCodeKey];
	
	__block NSArray *locales;
	
	CachedHandler cachedLocales = ^()
	{
		[self preLoadLocalesAsCache:YES];
	};
	
	NSString *apiCall = [NSString stringWithFormat:@"%@?%@=%@", LOCALES, LOCALE, _languageCode];
	
	shouldContinue = [self loadAndParseApiRequest:apiCall
										  eTagKey:CLALocalesEtagKey
									cachedHandler:cachedLocales
								completionHandler:^BOOL(NSData *response)
	{
		[self preLoadLocalesAsCache:NO];
		
		NSError *error;
		
		locales = [self importLocalesJSON:response error:&error];
		
		if (!locales)
			return [self quitWithError:error];
		
		NSString *preferredLanguageCode = [self.preferences valueForKey:CLAPreferredLanguageCodeKey];
		
		NSUInteger found = [locales indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
		{
			id <CLALocale>locale = (id <CLALocale>)obj;
			
			if ([preferredLanguageCode isEqualToString:[locale languageCode]])
				return YES;
			
			return NO;
			
		}];
		
		
		if (found != NSNotFound)
		{
			_languageCode = preferredLanguageCode;
		}
		else
		{
			_languageCode = [self.preferences valueForKey:CLADefaultLanguageCodeKey];
		}
		
		[self.preferences setValue:_languageCode forKey:CLAPreferredLanguageCodeKey];

		return YES;
	}];
	
	
	if (!shouldContinue)
		return;

	__block NSArray *topics;
	
	CachedHandler cachedTopic = ^
	{
		[self preLoadTopicsAsCache:YES];
	};
	
	apiCall = [NSString stringWithFormat:@"%@?%@=%@", CATEGORIES, LOCALE, _languageCode];
	
	shouldContinue =	[self loadAndParseApiRequest:apiCall
										  eTagKey:CLATopicEtagKey
									cachedHandler:cachedTopic
								completionHandler:^BOOL(NSData *response)
						{
							[self preLoadTopicsAsCache:NO];
							
							NSError *error;
							topics = [self importTopicsJSON:response error:&error];
							
							if (!topics)
								return [self quitWithError:error];
							
							return YES;
							
						}];

	if (!shouldContinue)
		return;
	
	[[self notificationQueue] addOperationWithBlock:^()
	 {
		 [self.delegate fetchManagerdidStartFetchingData:self];
	 }];


	NSParameterAssert(sizeof(self.position));

	if (_fetchSingleContent)
	{
		apiCall = [NSString stringWithFormat:@"%@/%@?%@=%@", SINGLECONTENT, self.singleContentId, LOCALE, _languageCode];
	}
	else
	{
		apiCall = [NSString stringWithFormat:@"%@?%@=%f+%f&%@=%@", CONTENTS, POSITION, self.position.latitude, self.position.longitude, LOCALE, _languageCode];
	}
	
	CachedHandler cachedContent = ^
	{
		[self preLoadMediasAsCache:YES];
		[self preLoadContentsAsCache:YES];
	};
	
	shouldContinue = [self loadAndParseApiRequest:apiCall
										  eTagKey:CLAContentEtagKey
									cachedHandler:cachedContent
								completionHandler:^BOOL(NSData *response)
					  {
						  [self preLoadMediasAsCache:_fetchSingleContent];
						  [self preLoadContentsAsCache:_fetchSingleContent];
						  
						  NSError *error;
						  NSArray *contents = [self importContentsJSON:response error:&error];
						  
						  if (!contents)
							  return [self quitWithError:error];
						  
						  return YES;
						  
					  }];
	

	
	if (shouldContinue)
	{

		 NSError *error;
		 
		 [self switchData];
		 
		 [self.context save:&error];
		 
		 if (error)
		 {
			 NSLog(@"CLAFetchManager - error saving in context:\n%@\n", [error localizedDescription]);
			 NSLog(@"%@\n", [error userInfo][NSDetailedErrorsKey]);
			 
			 [self quitWithError:error];
		 }
		 else
		 {
			 [[self notificationQueue] addOperationWithBlock:^()
			 {
				 [self.delegate fetchManagerDidFinishFetchingData:self];
			 }];
		 }
		 
	
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

-(void)mergeObjects:(NSNotification *)notification
{
	
	if ([notification object] == self.context)
	{
		return;
	}
	
	[self.consumerQueue addOperationWithBlock:^()
	{
		[self.context mergeChangesFromContextDidSaveNotification:notification];
	}];
	
	


}

-(NSOperationQueue *)notificationQueue
{
	if (!_notificationQueue)
	{
		_notificationQueue = [NSOperationQueue mainQueue];
	}
	
	return _notificationQueue;
	
}

-(NSArray *)importJSON:(NSData *)jsonData parseBlock:(ParseHandler)block error:(NSError *__autoreleasing *)error
{
	NSParameterAssert(jsonData);
	NSParameterAssert(block);
	
	[self setupManagerObjects];
	
	NSError *err;
	
	NSArray *items = block(jsonData, &err);
	
	if (!items)
	{
		NSLog(@"CLAFetchManager - error parsing JSON:\n%@\nJSON Data:%@\n", [err localizedDescription],  jsonData);
		
		if (error)
			*error = err;
	}
	
	return items;
}

-(BOOL)loadAndParseApiRequest:(NSString *)apiRequest eTagKey:(NSString *)key cachedHandler:(CachedHandler)cachedHandler completionHandler:(ResponseHandler)handler
{
	NSError *error;
	NSHTTPURLResponse *response;
	
	NSString *eTag = [[NSUserDefaults standardUserDefaults] stringForKey:key];
	
	NSString *stringURL = [_endpoint stringByAppendingPathComponent:apiRequest];
	NSURL *url = [NSURL URLWithString:stringURL];

	NSParameterAssert(url);
	NSParameterAssert(key);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestReloadRevalidatingCacheData
													   timeoutInterval:self.httpTimeout];
	
	if (eTag)
	{
		[request setValue:eTag forHTTPHeaderField:@"If-None-Match"];
	}
	
#ifdef DEBUG
	NSLog(@"Calling api request: %@\n", [url absoluteString]);
	NSLog(@"Using HTTP Header fields: %@\n %@", request, [request allHTTPHeaderFields]);
#endif
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request
												 returningResponse:&response
															 error:&error];
#ifdef DEBUG
	if ([responseData bytes])
	{
			NSLog(@"Server Response: %i\n %@\n%@", [response statusCode],[response allHeaderFields], [NSString stringWithUTF8String:[responseData bytes]]);
	}

#endif
	
	if (responseData)
	{
		if ([responseData length] > 0)
		{
			NSURL *path = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
			
			NSString *lastComponent = [apiRequest lastPathComponent];
			
			path = [path URLByAppendingPathComponent:lastComponent];
			
			[responseData writeToURL:path options:NSDataWritingAtomic error:nil];
		}

	}

	
	if ((eTag = [response allHeaderFields][@"Etag"]))
	{
		[[NSUserDefaults standardUserDefaults] setObject:eTag forKey:key];
	}
	
	if (HTTP200OK == response.statusCode)
	{
		return handler(responseData);
	}
	else if (HTTP304OK == response.statusCode)
	{
		cachedHandler();
		return YES;
	}
	else if (!responseData)
	{
		NSLog(@"CLAFetchManager - error connecting to %@:\n%@\n", [url absoluteString], [error localizedDescription]);
		
		return [self quitWithError:error];
	}
	else
	{
		error = [NSError errorWithDomain:@"HTTPResponseDomain"
									code:response.statusCode
								userInfo:nil];
		
		NSLog(@"CLAFetchManager - error response from server:%@\nLoading URL: %@", [error localizedDescription], [url absoluteString]);
		
		return [self quitWithError:error];
	}
}


- (BOOL)quitWithError:(NSError *)error
{
	[[self notificationQueue] addOperationWithBlock:^()
	{
		[self.delegate fetchMananager:self didFailWithError:error];
	}];
	
	return NO;
}

- (void)setupManagerObjects
{
	NSParameterAssert(self.coordinator);
	
	if (!self.dataParser)
	{
		self.dataParser = [[CLADataParser alloc] init];
		self.dataParser.delegate = self;
	}
	
	if (!_context)
	{
		_context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];

		[_context setPersistentStoreCoordinator:self.coordinator];

	}
}

-(void)preLoadEntity:(NSString *)entity asCache:(BOOL)cached
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
	
	NSError *error;
	NSArray *resultSet;
	
	resultSet = [self.context executeFetchRequest:fetchRequest error:&error];

	
	if (!resultSet)
	{
		NSLog(@"Error preloading @%@: %@", entity, error);
		abort();
	}
	
	if (cached)
	{
		[resultSet enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		 {
			 NSManagedObject *managedObject = (NSManagedObject *)obj;
			 [managedObject setValue:@YES forKey:@"hidden"];

		 }];
	}

	[self setValue:[NSMutableArray arrayWithArray:resultSet] forKey:_collectionEntities[entity]];
	
}

-(void)preLoadTopicsAsCache:(BOOL)cached
{
	[self preLoadEntity:@"Topic" asCache:cached];
}

-(void)preLoadMediasAsCache:(BOOL)cached
{
	[self preLoadEntity:@"Image" asCache:cached];
}

-(void)preLoadContentsAsCache:(BOOL)cached
{
	[self preLoadEntity:@"Item" asCache:cached];
}

-(void)preLoadLocalesAsCache:(BOOL)cached
{
	[self preLoadEntity:@"Locale" asCache:cached];
}

-(void)switchData
{
	NSPredicate *hidden = [NSPredicate predicateWithFormat:@"%K == %@", @"hidden", @NO];

	NSDictionary *collections = @{@"_collectedMedias"	: _collectedMedias,
								  @"_collectedContents"	: _collectedContents,
								  @"_collectedTopics"	: _collectedTopics,
								  @"_collectedLocales"  : _collectedLocales};
	
	for (NSString *key in collections)
	{
		NSArray *collection = collections[key];
		NSArray *toDelete	= [collection filteredArrayUsingPredicate:hidden];
		
		for (NSManagedObject *object in toDelete)
		{
			[self.context deleteObject:object];
		}
		
		[collection enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		{
			NSManagedObject *managedObject = (NSManagedObject *)obj;
			[managedObject setValue:@NO forKey:@"hidden"];
		}];
	}
	
}

#pragma mark - CLADataParserHelperProtocol

-(id <CLATopic>)topicObjectForTopicCode:(NSString *)code
{
	NSParameterAssert(code);
	NSParameterAssert([code isKindOfClass:[NSString class]]);

	id <CLATopic> topic;

	NSAssert(_collectedTopics, @"Should have a _collectedTopics set!\n");

	NSInteger found = [_collectedTopics indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
	{
		BOOL found = NO;
		
		id <CLATopic> topic = (id <CLATopic>)obj;
		
		if ([[topic topicCode] isEqualToString:code])
		{
			*stop = YES;
			found = YES;
		}
		
		return found;
	}];
	
	
	if (found != NSNotFound)
	{
		topic = [_collectedTopics objectAtIndex:found];
		[(NSObject *)topic setValue:@YES forKey:@"hidden"];
	}
	else
	{
		topic = [NSEntityDescription insertNewObjectForEntityForName:@"Topic" inManagedObjectContext:self.context];
		[_collectedTopics addObject:topic];
	}

	return topic;
}

-(id <CLAItem>)itemObjectForItemId:(NSString *)itemId topicCode:(NSString *)topicCode
{
	NSParameterAssert(topicCode);
	NSParameterAssert(itemId);
	NSParameterAssert([itemId isKindOfClass:[NSString class]]);
	
	NSAssert(_collectedContents, @"Should have a _collectedContents set!\n");
	
	id <CLAItem>item;
	id <CLATopic>topic;
	
	NSInteger found = [_collectedTopics indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
	{
	   BOOL found = NO;
	   
	   id <CLATopic> topic = (id <CLATopic>)obj;
	   
	   if ([[topic topicCode] isEqualToString:topicCode])
	   {
		   *stop = YES;
		   found = YES;
	   }
	   
	   return found;
	}];
	
	NSAssert(found != NSNotFound, @"should have already a topic!");
	
	topic = [_collectedTopics objectAtIndex:found];
	
	found = [_collectedContents indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
	{
	   BOOL found = NO;
	   
	   id <CLAItem> item = (id <CLAItem>)obj;
	   
	   if ([[item identifier] isEqualToString:itemId])
	   {
		   *stop = YES;
		   found = YES;
	   }
	   
	   return found;
	}];
	
	if (found != NSNotFound)
	{
		item = [_collectedContents objectAtIndex:found];
		[(NSObject *)item setValue:@YES forKey:@"hidden"];
	}
	else
	{
		item = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.context];
		[_collectedContents addObject:item];
	}
	
	[item setTopic:topic];
	
	return item;
}

-(id <CLAImage>)imageObjectForImageCode:(NSString *)code forItem:(id<CLAItem>)item
{
	NSParameterAssert(item);
	NSParameterAssert(code);

	id <CLAImage> image;
	
	NSInteger found = [_collectedMedias indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
	{
	   BOOL found = NO;
	   
	   id <CLAImage> image = (id <CLAImage>)obj;
	   
	   if ([[image imageURL] isEqualToString:code] && [image item] == item)
	   {
		   *stop = YES;
		   found = YES;
	   }
	   
	   return found;
	}];
	
	if (found != NSNotFound)
	{
		image = [_collectedMedias objectAtIndex:found];
		[(NSObject *)image setValue:@YES forKey:@"hidden"];
	}
	else
	{
		image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:self.context];
		[_collectedMedias addObject:image];
	}
	
	[image setItem:item];

	return image;
}

-(id <CLALocale>)localeObjectForLanguageKey:(NSString *)key
{
	NSParameterAssert(key);
	
	id <CLALocale> requestedLocale;
	
	NSUInteger found  = [_collectedLocales indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
		{
			id <CLALocale> locale = (id <CLALocale>)obj;
			
			if ([[locale languageCode] isEqualToString:key])
			{
				return YES;
				*stop = YES;
			}
			
			return NO;
		}];
	
	
	if (found != NSNotFound)
	{
		requestedLocale = [_collectedLocales objectAtIndex:found];
		[(NSObject *)requestedLocale setValue:@YES forKey:@"hidden"];
	}
	else
	{
		requestedLocale = [NSEntityDescription insertNewObjectForEntityForName:@"Locale"
														inManagedObjectContext:self.context];
		[_collectedLocales addObject:requestedLocale];
	}
	
	return requestedLocale;
}

@end
