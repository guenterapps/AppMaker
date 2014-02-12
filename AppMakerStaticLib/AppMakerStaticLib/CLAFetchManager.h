//
//  CLAFetchManager.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 10/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CLAFetchManagerDelegate.h"
#import "CLADataParserHelperProtocol.h"

@class NSPersistentStoreCoordinator, NSManagedObjectContext, CLADataParser, CLAPreferences;

@interface CLAFetchManager : NSOperation <CLADataParserHelperProtocol>
{
	NSString *_endpoint;
	
	NSMutableArray *_collectedTopics;
	NSMutableArray *_collectedContents;
	NSMutableArray *_collectedMedias;
	NSMutableArray *_collectedLocales;
}

@property (nonatomic) CLAPreferences *preferences;

@property (nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, readonly) NSManagedObjectContext *context;

@property (nonatomic) CLADataParser *dataParser;
@property (nonatomic) id <CLAFetchManagerDelegate> delegate;

@property (nonatomic) CLLocationCoordinate2D position;
@property (nonatomic) NSTimeInterval httpTimeout;
@property (nonatomic) NSString *singleContentId;

-(id)initWithEndpoint:(NSString *)endPoint; //get full data
//-(id)initForTopic:(NSString *)topic withEndpoint:(NSString *)endPoint;

//Exposed methods for loading seed data
//These methods don't commit changes! Client must call save:error:
//through performBlock: on fetchManager context.

-(NSArray *)importContentsJSON:(NSData *)jsonData error:(NSError **)error;
-(NSArray *)importTopicsJSON:(NSData *)jsonData error:(NSError **)error;
-(NSArray *)importLocalesJSON:(NSData *)jsonData error:(NSError **)error;

@end
