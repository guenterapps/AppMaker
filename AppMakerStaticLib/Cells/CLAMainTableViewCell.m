//
//  CLAMainTableViewCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 05/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAMainTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UITableViewCell+Common.h"
#import "UITextView+Utilities.h"

@interface CLAMainTableViewCell	()
{
	NSLayoutConstraint *_titleViewConstraint;
}

@end

@implementation CLAMainTableViewCell

-(void)awakeFromNib
{
	
	_titleViewConstraint = [NSLayoutConstraint constraintWithItem:_titleLabel
														attribute:NSLayoutAttributeHeight
														relatedBy:NSLayoutRelationEqual
														   toItem:nil
														attribute:NSLayoutAttributeNotAnAttribute
													   multiplier:1.0
														 constant:1.0];
	
	
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
