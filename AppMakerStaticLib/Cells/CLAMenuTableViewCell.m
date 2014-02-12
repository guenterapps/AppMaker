//
//  CLAMenuTableViewCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAMenuTableViewCell.h"

@implementation CLAMenuTableViewCell

-(void)prepareForReuse
{
	_title.text = nil;
}

-(void)setTitle:(NSString *)title
{
	_title.text = [title copy];
}

@end
