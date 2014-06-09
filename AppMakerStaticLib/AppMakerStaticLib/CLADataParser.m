//
//  CLADataParser.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 10/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLADataParser.h"

static NSDateFormatter *dateFormatter;


@implementation CLADataParser

-(id)init
{
	if (self = [super init])
	{
		topicMap = @{@"code"		: @"topicCode",
					 @"name"		: @"title",
					 @"updated_at"	: @"lastUpdated",
					 @"created_at"	: @"created",
					 @"sort"		: @"sortOrder",
					 @"position"	: @"ordering"
					 };
		
		itemMap = @{@"name"			: @"title",
					@"id"			: @"identifier",
					@"description"	: @"detailText",
					@"address"		: @"address",
					@"zipcode"		: @"zipcode",
					@"city"			: @"city",
					@"type"			: @"type",
					@"subtype"		: @"subType",
					@"updated_at"	: @"lastUpdated",
					@"created_at"	: @"created",
					@"date"			: @"date",
					@"website"		: @"urlAddress",
					@"phone"		: @"phoneNumber",
					@"position"		: @"ordering"
					};
		
		mediaMap = @{@"type"		: @"type",
					 @"updated_at"	: @"lastUpdated"};
		
		if (!dateFormatter)
		{
			dateFormatter = [[NSDateFormatter alloc] init];
			
			[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss+SSSS"];
		}
	}
	
	return self;
}

-(NSArray *)parseLocales:(NSData *)localesData error:(NSError *__autoreleasing *)error
{
	NSAssert(self.delegate, @"Cannot parse without my delegate!\n");
	
	NSDictionary *locales = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:localesData
																			options:0
																			  error:error];
	NSArray *allLocales;
	
	if (locales)
	{
		
		NSAssert([locales isKindOfClass:[NSDictionary class]], @"Should be a dictionary");
		
		NSMutableArray *collectedLocales = [NSMutableArray array];
		NSInteger ordering = 0;
		
		for (NSString *key in locales)
		{
			id <CLALocale> locale = [self.delegate localeObjectForLanguageKey:key];
			
			[locale setLanguageCode:key];
			[locale setLanguageDescription:locales[key]];
			[(NSObject *)locale setValue:@(ordering++) forKey:@"ordering"];
			
			[collectedLocales addObject:locale];
			
		}
		
		allLocales = [NSArray arrayWithArray:collectedLocales];
	}
	
	return allLocales;
	
}

-(NSArray *)parseTopics:(NSData *)topicsData error:(NSError *__autoreleasing *)error
{
	NSAssert(self.delegate, @"Cannot parse without my delegate!\n");
	
	id topics = [NSJSONSerialization JSONObjectWithData:topicsData
												options:0
												  error:error];
	
	NSMutableArray *collectedTopics = [[NSMutableArray alloc] init];;
	
	void (^propertyHander)(id, NSDictionary *) = ^(id _topic, NSDictionary *_topicDictionary)
	{
		[collectedTopics addObject:_topic];
		
		for (NSString *key in topicMap)
		{
			if ([@"updated_at" isEqualToString:key])
			{
				NSDate *lastUpdate = [dateFormatter dateFromString:_topicDictionary[key]];
				[_topic setValue:lastUpdate forKey:topicMap[key]];
				
				continue;
				
			}
			else if ([@"created_at" isEqualToString:key])
			{
				NSDate *created = [dateFormatter dateFromString:_topicDictionary[key]];
				[_topic setValue:created forKey:itemMap[key]];
				
				continue;
				
			}
			
			[_topic setValue:_topicDictionary[key] forKey:topicMap[key]];
		}
	};
	
	if (topics)
	{
		NSAssert([topics isKindOfClass:[NSArray class]], @"We should get an array of Topics!\n");
		
		for (NSDictionary *topicDictionary in topics)
		{
			id code		= topicDictionary[@"code"];
			
			if ([code isKindOfClass:[NSNumber class]])
			{
				code = [(NSNumber *)code stringValue];
			}
			
			NSObject *topic = (NSObject *)[self.delegate topicObjectForTopicCode:code];
			
			propertyHander(topic, topicDictionary);

			for (id subDictionary in topicDictionary[@"children"])
			{
				code	= subDictionary[@"code"];
				
				if ([code isKindOfClass:[NSNumber class]])
				{
					code = [(NSNumber *)code stringValue];
				}
				
				NSObject *subTopic = (NSObject *)[self.delegate topicObjectForTopicCode:code];
				
				propertyHander(subTopic, subDictionary);
				
				[subTopic setValue:topic forKey:@"parentTopic"];
				
			}
			
		}
	}
	
	
	return collectedTopics;
}

-(NSArray *)parseContents:(NSData *)contentsData error:(NSError *__autoreleasing *)error
{
	NSAssert(self.delegate, @"Cannot parse without my delegate!\n");
	
	id contents = [NSJSONSerialization JSONObjectWithData:contentsData
												  options:0
													error:error];
	NSMutableArray *collectedObjects;
	//	NSInteger ordering = 0;
	
	if (contents)
	{
		NSAssert([contents isKindOfClass:[NSArray class]], @"We should get an array of Contents!\n");
		
		collectedObjects = [[NSMutableArray alloc] init];
		
		for (NSDictionary *contentDictionary in contents)
		{
			id topic		= contentDictionary[@"category"][@"code"];
			id identifier	= contentDictionary[@"id"];
			
			if ([identifier isKindOfClass:[NSNumber class]])
			{
				identifier = [(NSNumber *)identifier stringValue];
			}
			if ([topic isKindOfClass:[NSNumber class]])
			{
				topic = [(NSNumber *)topic stringValue];
			}
			
			NSAssert(topic, @"Contents should have an associated topic!\n");
			NSAssert(identifier, @"Contents should have an 'id' key!\n");
			
			NSObject *content = [self.delegate itemObjectForItemId:identifier topicCode:topic];
			
			[collectedObjects addObject:content];
			
			//			[content setValue:[NSNumber numberWithInteger:ordering++] forKey:@"ordering"];
			
			double latitude		= [contentDictionary[@"latitude"] doubleValue];
			double longitude	= [contentDictionary[@"longitude"] doubleValue];
			
			if (latitude && longitude)
			{
				CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
				[(id <CLAItem>)content setCoordinate:coordinate];
			}
			
			for (NSString *key in itemMap)
			{
				if (contentDictionary[key] == [NSNull null])
					continue;

				if ([@"updated_at" isEqualToString:key])
				{
					NSDate *lastUpdate = [dateFormatter dateFromString:contentDictionary[key]];
					[content setValue:lastUpdate forKey:itemMap[key]];
					
					continue;
					
				}
				else if ([@"id" isEqualToString:key])
				{
					NSString *identifier = [(NSNumber *)contentDictionary[key] stringValue];
					[content setValue:identifier forKey:itemMap[key]];
					
					continue;
				}
				else if ([@"created_at" isEqualToString:key])
				{
					NSDate *created = [dateFormatter dateFromString:contentDictionary[key]];
					[content setValue:created forKey:itemMap[key]];
					
					continue;
					
				}
				else if ([@"date" isEqualToString:key])
				{
					NSDate *date = [dateFormatter dateFromString:contentDictionary[key]];
					[content setValue:date forKey:itemMap[key]];
					
					continue;
					
				}
				
				
				
				[content setValue:contentDictionary[key] forKey:itemMap[key]];
				
			}
			
			id medias = contentDictionary[@"medias"];
			
			if ([medias count] > 0)
			{
				NSParameterAssert([medias isKindOfClass:[NSArray class]]);
				
				NSInteger mediaOrdering = 0;
				
				for (NSDictionary *mediaDictionary in medias)
				{
					NSString *code;
					
					if ([@"video" isEqualToString:mediaDictionary[@"type"]])
					{
						code = mediaDictionary[@"thumb"];
					}
					else
					{
						code = mediaDictionary[@"url"];
					}
					
					if ([code length] == 0)
					{
						NSLog(@"Found empty url for image!");
						continue;
					}
					
					NSRange cutRange = [code rangeOfString:@"?"];
					
					if (cutRange.location != NSNotFound)
					{
						code = [code substringWithRange:NSMakeRange(0, cutRange.location)];
					}
					
					code = [code stringByAppendingString:@"?w=600&h=400"];
					
					NSObject *media = (NSObject *)[self.delegate imageObjectForImageCode:code forItem:(id <CLAItem>)content];
					
					if (mediaOrdering == 0)
					{
						[media setValue:[NSNumber numberWithBool:YES] forKey:@"primary"];
					}
					
					[media setValue:[NSNumber numberWithInteger:mediaOrdering++] forKey:@"ordering"];
					
					if ([@"video" isEqualToString:mediaDictionary[@"type"]])
					{
						[media setValue:code forKey:@"imageURL"];
						[media setValue:mediaDictionary[@"url"] forKey:@"videoURL"];
					}
					else
					{
						[media setValue:code forKey:@"imageURL"];
						[media setValue:mediaDictionary[@"filename"] forKey:@"fileName"];
					}
					
					for (NSString *key in mediaMap)
					{
						if ([@"updated_at" isEqualToString:key])
						{
							NSDate *lastUpdate = [dateFormatter dateFromString:contentDictionary[key]];
							[media setValue:lastUpdate forKey:mediaMap[key]];
							
							continue;
							
						}
						
						[media setValue:mediaDictionary[key] forKey:mediaMap[key]];
					}
					
				}
				
			}
			
			
		}
	}
	
	return collectedObjects;
}


@end
