//
//  CLAImageFetch.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 15/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#define TIMEOUT 5

#import "CLAImageFetch.h"
#import <CoreData/CoreData.h>

NSString *CLAUpdatedObjectIDsKey = @"CLAUpdatedObjectIDsKey";

@interface CLAImageFetch ()
{
	NSURL *_imageURL;
	NSManagedObjectID *_objectId;
}

@property (nonatomic, copy) void (^completionHandler)(NSError *);

@end

@implementation CLAImageFetch

@synthesize context = _context, httpTimeout = _httpTimeout;

-(id)initWithURL:(NSString *)url forObject:(NSManagedObjectID *)objectId completionBlock:(void (^)(NSError *))block
{
	if (self = [super init])
	{
		_objectId = objectId;
		_imageURL = [NSURL URLWithString:url];
		self.completionHandler = block;
		
		//NSAssert(_imageURL, @"Could not convert to URL!");
	}
	
	return self;
	
}

-(id)initWithURL:(NSString *)url forObject:(NSManagedObjectID *)objectId
{
	return [self initWithURL:url forObject:objectId completionBlock:nil];
}

#pragma mark - Properties

-(NSManagedObjectContext *)context
{
	if (!_context)
	{
		NSAssert(self.coordinator, @"Should have a persistent store coordinator!");
		_context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		_context.persistentStoreCoordinator = self.coordinator;
	}
	
	return _context;
}

#pragma mark - Main

-(NSTimeInterval)httpTimeout
{
	if (!_httpTimeout)
	{
		_httpTimeout = TIMEOUT;
	}
	
	return _httpTimeout;
}

-(void)main
{
	__block NSError *error;

#ifdef DEBUG
	NSLog(@"Calling api request: %@", [_imageURL absoluteString]);
#endif
	
	NSData *imageData= [NSData dataWithContentsOfURL:_imageURL options:0 error:&error];
	NSDictionary *userInfo;
	
	if (!error)
	{
		NSManagedObject *imageObject = [self.context objectWithID:_objectId];
		
		[imageObject setValue:imageData forKey:@"imageData"];
		
		[self.context performBlockAndWait:^()
		 {
			 [self.context save:&error];
		 }];
		
		if (error)
		{
			NSLog(@"Error saving image at url %@: %@", [_imageURL absoluteString], error);
			abort();
		}
		
		userInfo = @{NSUpdatedObjectsKey	: @[imageObject],
					 CLAUpdatedObjectIDsKey : @[imageObject.objectID]};
	}
	else
	{
		NSLog(@"Error loading image at url %@: %@", [_imageURL absoluteString], error);
	}

	[[NSOperationQueue mainQueue] addOperationWithBlock:^()
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:NSManagedObjectContextDidSaveNotification object:self userInfo:userInfo];
		
		if (self.completionHandler)
			self.completionHandler(error);
			
	}];
	
}

@end
