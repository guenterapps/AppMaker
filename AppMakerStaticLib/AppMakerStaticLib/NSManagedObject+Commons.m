//
//  NSManagedObject+Commons.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "NSManagedObject+Commons.h"

@implementation NSManagedObject (Commons)

-(UIImage *)image
{
	[self willAccessValueForKey:@"image"];
	
	UIImage *image = [self primitiveValueForKey:@"image"];
	
	if (!image)
	{
		image = [UIImage imageWithData:[self primitiveValueForKey:@"imageData"]];
		
		[self setPrimitiveValue:image forKey:@"image"];
	}
	
	[self didAccessValueForKey:@"image"];
	
	return image;
}

-(void)setImage:(UIImage *)image
{
	[self willChangeValueForKey:@"image"];
	
	NSData *imageData = UIImagePNGRepresentation(image);
	
	[self setPrimitiveValue:imageData forKey:@"imageData"];
	
	[self didChangeValueForKey:@"image"];
}

@end
