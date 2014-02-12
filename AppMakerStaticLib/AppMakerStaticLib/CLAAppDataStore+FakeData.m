//
//  CLAAppDataStore+FakeData.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAAppDataStore+FakeData.h"
#import <CoreData/CoreData.h>
#import "Item.h"
#import "Image.h"

@implementation CLAAppDataStore (FakeData)

-(void)setupFakeData
{
	
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Item"];
	
	NSError *error;
	
	if ([self.context countForFetchRequest:request error:&error] > 0 || error)
		return;
	
	for (int k = 0; k < 5; k++)
	{
		
		Topic *newTopic =  [NSEntityDescription insertNewObjectForEntityForName:@"Topic" inManagedObjectContext:self.context];
		
		[newTopic setValue:@(k) forKey:@"ordering"];
		
		[newTopic setValue:@NO forKey:@"hidden"];
		
		newTopic.title = [NSString stringWithFormat:@"Topic %i", k];
		newTopic.topicCode = newTopic.title;
	
		for (int i = 1; i <= 10; i++)
		{
			Item *item = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.context];
			
			[item setValue:@NO forKey:@"hidden"];
			[item setValue:@(i) forKey:@"ordering"];
			
			[item setTitle:[NSString stringWithFormat:@"Baretto %i %@", i, newTopic.title]];
			
			double delta = rand() % 999999;
			
			int sign = (delta - 555555) > 0 ? 1 : -1;
			
			NSString *descText = @"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.";
		
			
			double latitude = 41.867459 + sign * (delta * pow(10, -9));
			double longitude = 12.468695 + sign * (delta * pow(10, -9));

			[item setDetailText:descText];
			[item setTopic:newTopic];
			[item setType:@"generic"];
			[item setSubType:@"poi"];
			
			
			NSMutableSet *images = [item mutableSetValueForKey:@"images"];
			
			for (int j = 0; j < 4; j++)
			{
				Image *image =  [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:self.context];
				
				[image setValue:@(j) forKey:@"ordering"];
				[image setValue:@NO forKey:@"hidden"];
				[image setType:@"image"];
				
				if (j == 0)
				{
					[image setPrimary:@YES];
				}

				UIImage *detailImage = [UIImage imageNamed:[NSString stringWithFormat:@"%i.jpg", 10+j]];
				
				[image setImage:detailImage];
				
				[images addObject:image];
			}
			
			if (sign > 0)
			{
				item.eMailAddress = [NSString stringWithFormat:@"Email%i@email.it", i];
				item.phoneNumber  = [NSString stringWithFormat:@"123213"];
			}
			
			item.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
		}
	}
	
	[self.context save:&error];
	
	if (error)
	{
		
		NSString *errDesc = [NSString stringWithFormat:@"%@", [[error userInfo] objectForKey:NSDetailedErrorsKey]];
		NSLog(@"%@", errDesc);
		
		[[[UIAlertView alloc] initWithTitle:[error localizedDescription]
									message:errDesc
								   delegate:nil
						  cancelButtonTitle:@"Cancel"
						  otherButtonTitles:nil] show];
	}

}

@end
