//
//  CLAMenuTableViewCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAMenuTableViewCell.h"

@implementation CLAMenuTableViewCell

-(void)awakeFromNib
{
	[super awakeFromNib];
	
	self.subCategoryArrow.image = [self.subCategoryArrow.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	//self.subCategoryArrow.transform = CGAffineTransformMakeRotation(0);
}

-(void)prepareForReuse
{
	_title.text = nil;
	self.subCategoryArrow.hidden = YES;
	self.subCategoryArrow.tintColor = nil;
}

-(void)setTitle:(NSString *)title
{
	_title.text = [title copy];
}

@end
