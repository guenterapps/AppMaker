//
//  CLADescriptionDetailCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 08/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLADescriptionDetailCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UITableViewCell+Common.h"
#import "UITextView+Utilities.h"

@interface CLADescriptionDetailCell ()
{
	NSLayoutConstraint *_titleViewConstraint;
}

@end


@implementation CLADescriptionDetailCell

-(void)awakeFromNib
{
	_titleViewConstraint = [NSLayoutConstraint constraintWithItem:self.titleTextView
														attribute:NSLayoutAttributeHeight
														relatedBy:NSLayoutRelationEqual
														   toItem:nil
														attribute:NSLayoutAttributeNotAnAttribute
													   multiplier:1.
														 constant:1.];
	[_backview addConstraint:_titleViewConstraint];
	
	[self setupShadowOnView:_backview];
	
	_backview.layer.shouldRasterize = YES;
	_backview.layer.rasterizationScale = [[UIScreen mainScreen] scale];
	
	self.detailTextView.layer.borderColor		= [UIColor whiteColor].CGColor;
	self.detailTextView.layer.borderWidth		= 2.0;
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
	{
		UIEdgeInsets textInsets;
		
		textInsets = self.detailTextView.textContainerInset;
		self.detailTextView.textContainerInset = UIEdgeInsetsMake(textInsets.top, textInsets.left + 4.0, textInsets.bottom, textInsets.right + 4.);

		textInsets = self.titleTextView.textContainerInset;
		self.titleTextView.textContainerInset = UIEdgeInsetsMake(textInsets.top, textInsets.left + 4.0, textInsets.bottom, textInsets.right + 4.);
	
	}
	
}

-(void)updateConstraints
{
	_titleViewConstraint.constant = [self.titleTextView heightForTextView] ;

	[super updateConstraints];
}

-(CALayer *)actualShadowLayer
{
	return _backview.layer;
}

//
// NB constranints are automatically added when xib is compiled
//-(void)layoutSubviews
//{
//	[super layoutSubviews];
//	
//	CGRect bottomImageViewFrame		= self.bottomImageView.frame;
//	CGRect textViewFrame			= self.detailTextView.frame;
//	
//	textViewFrame.size.height		= self.detailTextView.contentSize.height;
//	bottomImageViewFrame.origin.y	= textViewFrame.size.height + textViewFrame.origin.y;
//	
//	self.bottomImageView.frame		= bottomImageViewFrame;
//	self.detailTextView.frame		= textViewFrame;
//
//}

@end
