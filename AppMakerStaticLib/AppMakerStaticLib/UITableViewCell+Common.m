//
//  UITableViewCell+Common.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 22/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "UITableViewCell+Common.h"
#import "CLATableViewCellConfigurationProtocol.h"
#import <QuartzCore/QuartzCore.h>

@implementation UITableViewCell (Common)

//-(void)setupShadowOnView:(UIView *)view
//{
//	//view.layer.shadowColor		= [UIColor blackColor].CGColor;
//	view.layer.shadowOffset		= CGSizeMake(0.0, 0.0);
////	view.layer.shadowRadius		= 4.0;
//	view.layer.shadowOpacity	= 0.8;
//
//}

-(void)setShadowColor:(UIColor *)color
{
	NSAssert([self conformsToProtocol:@protocol(CLATableViewCellConfigurationProtocol)], @"Cannot invoke this method on a cell that does not implement CLATableViewCellConfigurationProtocol!");
	
	if (!color)
		return;
	
	id <CLATableViewCellConfigurationProtocol>cell = (id <CLATableViewCellConfigurationProtocol>)self;
	
	[cell actualShadowLayer].shadowOpacity	= 0.8;
	[cell actualShadowLayer].shadowOffset	= CGSizeMake(0.0, 0.0);
	[cell actualShadowLayer].shadowColor	= color.CGColor;
}

@end
