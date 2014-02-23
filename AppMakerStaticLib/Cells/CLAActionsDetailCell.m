//
//  CLAActionsDetailCell.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 08/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAActionsDetailCell.h"
#import "UITableViewCell+Common.h"

@implementation CLAActionsDetailCell

-(void)awakeFromNib
{
	//[self setupShadowOnView:_backView];
}


-(void)setBackviewColor:(UIColor *)color
{
	[_backView setBackgroundColor:color];
}

-(CALayer *)actualShadowLayer
{
	return _backView.layer;
}

@end
