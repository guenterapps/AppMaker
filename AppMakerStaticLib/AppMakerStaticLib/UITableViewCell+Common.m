//
//  UITableViewCell+Common.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 22/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "UITableViewCell+Common.h"
#import <QuartzCore/QuartzCore.h>

@implementation UITableViewCell (Common)

-(void)setupShadowOnView:(UIView *)view
{
	view.layer.shadowColor		= [UIColor blackColor].CGColor;
	view.layer.shadowOffset		= CGSizeMake(0.0, 0.0);
//	view.layer.shadowRadius		= 4.0;
	view.layer.shadowOpacity	= 0.8;

}

@end
