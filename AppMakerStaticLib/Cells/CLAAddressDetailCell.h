//
//  CLAAddressDetailCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 08/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLATableViewCellConfigurationProtocol.h"

@interface CLAAddressDetailCell : UITableViewCell <CLATableViewCellConfigurationProtocol>
{
	__weak IBOutlet UIImageView *_backgroundImageView;
	
	__weak IBOutlet UIImageView *_detailImageView;
	__weak IBOutlet UIImageView *_accessoryImageView;
	__weak IBOutlet UILabel *_titleLabel;
	__weak IBOutlet UILabel *_subtitleLabel;
}

-(void)setBackgroundImage:(UIImage *)image;
-(void)setDetailImage:(UIImage *)image;
-(void)setAccessoryImage:(UIImage *)image;
-(void)setTitle:(NSString *)title;
-(void)setSubtitle:(NSString *)subtitle;

@end
