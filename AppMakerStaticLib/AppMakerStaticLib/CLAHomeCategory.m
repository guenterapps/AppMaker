//
//  CLAHomeCategory.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 06/04/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAHomeCategory.h"

@implementation CLAHomeCategory

@synthesize created;
@synthesize lastUpdated;
@synthesize topicCode;
@synthesize title;
@synthesize items;
@synthesize sortOrder;
@synthesize ordering;

+(instancetype)homeCategory
{
	static CLAHomeCategory *homeCategory;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		homeCategory = [[self alloc] init];
	});
	
	return homeCategory;
}

-(id)init
{
	if (self = [super init])
	{
		NSDate *now = [NSDate date];

		self.created		= now;
		self.lastUpdated	= now;
		self.title			= @"Home";
		self.topicCode		= @"Home";
		self.ordering		= @(NSIntegerMax);
		self.sortOrder		= ORDERBY_POSITION;
		self.items			= [NSSet set];
		
	}
	
	return self;
}

@end
