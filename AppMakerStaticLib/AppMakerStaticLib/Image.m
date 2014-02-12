//
//  Images.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "Image.h"
#import "Item.h"


@implementation Image

@dynamic image;
@dynamic imageData;
@dynamic item;
@dynamic primary;
@dynamic videoURL;
@dynamic imageURL;
@dynamic fileName;
@dynamic type;
@dynamic ordering;
@dynamic lastUpdated;
@dynamic created;


-(UIImage *)image
{
	[self willAccessValueForKey:@"image"];
	
	UIImage *primitiveValue = [self primitiveValueForKey:@"image"];
	
	if (!primitiveValue)
	{
		NSData *imageData = [self primitiveValueForKey:@"imageData"];
		
		primitiveValue = [UIImage imageWithData:imageData];
		
		[self setPrimitiveValue:primitiveValue forKey:@"image"];
	}
	
	[self didAccessValueForKey:@"image"];

	return primitiveValue;

}

@end
