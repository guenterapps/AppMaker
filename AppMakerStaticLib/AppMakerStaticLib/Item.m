//
//  Item.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "Item.h"
#import "Topic.h"

#define SCALE [[UIScreen mainScreen] scale]
#define BORDER 2.0

@implementation Item

@dynamic title;
@dynamic coordinate;
@dynamic mainImage;
@dynamic latitude;
@dynamic longitude;
@dynamic topic;
@dynamic images;
@dynamic phoneNumber;
@dynamic eMailAddress;
@dynamic detailText;
@dynamic ordering;
@dynamic address;
@dynamic lastUpdated;
@dynamic identifier;
@dynamic city;
@dynamic zipcode;
@dynamic created;
@dynamic type;
@dynamic subType;
@dynamic pinMapData;
@dynamic pinMap;
@dynamic date;
@dynamic urlAddress;

-(CLLocationCoordinate2D)coordinate
{
	[self willAccessValueForKey:@"coordinate"];

	CLLocationCoordinate2D coordinate;
	
	double latitude		= [[self primitiveValueForKey:@"latitude"] doubleValue];
	double longitude	= [[self primitiveValueForKey:@"longitude"] doubleValue];
		
	coordinate = CLLocationCoordinate2DMake(latitude, longitude);
	
	[self didAccessValueForKey:@"coordinate"];
	
	return coordinate;
}

-(void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
	[self willChangeValueForKey:@"position"];
	
	NSNumber *latitude	= [NSNumber numberWithDouble:coordinate.latitude];
	NSNumber *longitude = [NSNumber numberWithDouble:coordinate.longitude];
	
	[self setPrimitiveValue:latitude forKey:@"latitude"];
	[self setPrimitiveValue:longitude forKey:@"longitude"];
	
	[self didChangeValueForKey:@"position"];
}

-(UIImage *)mainImage
{
	return [(NSManagedObject *)[self mainImageObject] valueForKey:@"image"];
}

-(id <CLAImage>)mainImageObject
{
	static NSPredicate *predicate;
	
	if (!predicate)
		predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"primary", @YES];
	
	NSSet *primary = [[self images] filteredSetUsingPredicate:predicate];
	
	NSParameterAssert([primary count] <= 1);
	
	return [primary anyObject];
}

-(UIImage *)pinMap
{
	[self willAccessValueForKey:@"pinMap"];
	
	UIImage *primitiveValue = [self primitiveValueForKey:@"pinMap"];
	
	if (!primitiveValue)
	{
		NSData *pinMapData = [self primitiveValueForKey:@"pinMapData"];
		
		primitiveValue = [UIImage imageWithData:pinMapData scale:2.0];
		
		[self setPrimitiveValue:primitiveValue forKey:@"pinMap"];
	}
	
	[self didAccessValueForKey:@"pinMap"];
	
	return primitiveValue;
	
}

-(void)generatePinMapFromMainImage
{

	UIImage *mainImage	= [self mainImage];
	UIImage *pinMap		= [UIImage imageNamed:@"pin"];
	NSData * pinMapData;
	
	CGSize pinSize = CGSizeMake(pinMap.size.width, pinMap.size.height);
		
	UIGraphicsBeginImageContextWithOptions(pinSize, NO, SCALE);
		
	[pinMap drawInRect:CGRectMake(0.0, 0.0, pinSize.width, pinSize.height)];
	[mainImage drawInRect:CGRectMake(BORDER, BORDER, pinSize.width - 2 * BORDER, pinSize.width - 2 * BORDER)];
		
	pinMap		= UIGraphicsGetImageFromCurrentImageContext();
	pinMapData	= UIImagePNGRepresentation(pinMap);
		
	[self setValue:pinMapData forKey:@"pinMapData"];
		
	UIGraphicsEndImageContext();

}


@end
