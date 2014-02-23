//
//  CLAHeaderDetailCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAHeaderDetailCell.h"
#import "UITableViewCell+Common.h"
#import <QuartzCore/QuartzCore.h>


@interface CLAHeaderDetailCell ()
{
	UIView *backView;
}

@end

@implementation CLAHeaderDetailCell

-(void)awakeFromNib
{
	backView = [[UIView alloc] initWithFrame:self.scrollView.frame];
	backView.backgroundColor = [UIColor blackColor];
	
	_backgroundImageView.layer.borderColor	= [UIColor whiteColor].CGColor;
	_backgroundImageView.layer.borderWidth	= 2.0;
	
	[self.contentView insertSubview:backView belowSubview:self.scrollView];

	//[self setupShadowOnView:backView];
	backView.layer.shadowPath		= [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;
	
	self.scrollView.layer.borderColor		= [UIColor whiteColor].CGColor;
	self.scrollView.layer.borderWidth		= 2.0;

}

-(void)setTitle:(NSString *)title
{
	_titleLabel.text = [title copy];
}

-(CALayer *)actualShadowLayer
{
	return backView.layer;
}


@end
