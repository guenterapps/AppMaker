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
	
	NSData *imageData = [self primitiveValueForKey:@"imageData"];
	UIImage *primitiveValue = [UIImage imageWithData:imageData scale:[[UIScreen mainScreen] scale]];;
	
	[self didAccessValueForKey:@"image"];
	
	return primitiveValue;
}

//-(void)setImage:(UIImage *)image
//{
//	[self willChangeValueForKey:@"image"];
//	
//	NSData *imageData = UIImagePNGRepresentation(image);
//	
//	[self setPrimitiveValue:imageData forKey:@"imageData"];
//	
//	[self didChangeValueForKey:@"image"];
//}

@end
