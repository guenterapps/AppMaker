//
//  CLAAddressDetailCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 08/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAAddressDetailCell.h"
#import <UITableViewCell+Common.h>
#import <QuartzCore/QuartzCore.h>

@implementation CLAAddressDetailCell


-(void)awakeFromNib
{
	[self setupShadowOnView:_backgroundImageView];
	_backgroundImageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:_backgroundImageView.bounds].CGPath;
}


-(void)setDetailImage:(UIImage *)image
{
	_detailImageView.image = image;
}

-(void)setAccessoryImage:(UIImage *)image
{
	_accessoryImageView.image = image;
}

-(void)setBackgroundImage:(UIImage *)image
{
	_backgroundImageView.image = image;
}

-(void)setTitle:(NSString *)title
{
	_titleLabel.text = [title copy];
}

-(void)setSubtitle:(NSString *)subtitle
{
	_subtitleLabel.text = [subtitle copy];
}

@end
