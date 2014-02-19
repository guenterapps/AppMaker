//
//  CLAEventTableViewCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 12/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAEventTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UITableViewCell+Common.h"
#import "UITextView+Utilities.h"

@interface CLAEventTableViewCell	()
{
	NSLayoutConstraint *_titleViewConstraint;
}

@end

@implementation CLAEventTableViewCell

-(void)awakeFromNib
{
	
	_titleViewConstraint = [NSLayoutConstraint constraintWithItem:_titleLabel
														attribute:NSLayoutAttributeHeight
														relatedBy:NSLayoutRelationEqual
														   toItem:nil
														attribute:NSLayoutAttributeNotAnAttribute
													   multiplier:1.0
														 constant:1.0];

	[_titleViewConstraint setPriority:UILayoutPriorityDefaultLow];
	
	
	[_titleLabel addConstraint:_titleViewConstraint];
	
	[self setupShadowOnView:_itemImageView];
	
	_itemImageView.layer.borderColor		= [UIColor whiteColor].CGColor;
	_itemImageView.layer.borderWidth		= 2.0;
	_backgroundImageView.layer.borderColor	= [UIColor whiteColor].CGColor;
	_backgroundImageView.layer.borderWidth	= 2.0;
	
	_itemImageView.layer.shadowPath			= [UIBezierPath bezierPathWithRect:_itemImageView.layer.bounds].CGPath;
}

-(void)updateConstraints
{
	_titleViewConstraint.constant = [_titleLabel heightForTextView];
	
	[super updateConstraints];
}

#pragma mark - Properties

-(void)setTitle:(NSString *)title
{
	_titleLabel.text = [title copy];
	
	[self setNeedsUpdateConstraints];
}

-(void)setImage:(UIImage *)image
{
	_itemImageView.image = image;
}

-(void)prepareForReuse
{
	_itemImageView.image = nil;
	_titleLabel.text	= nil;
	[self.layer removeAllAnimations];
}

-(CALayer *)actualShadowLayer
{
	return _itemImageView.layer;
}

@end
