//
//  CLAMainTableViewCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 05/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLATableViewCellConfigurationProtocol.h"

@interface CLAMainTableViewCell : UITableViewCell <CLATableViewCellConfigurationProtocol>
{
	
	__weak IBOutlet UIImageView *_itemImageView;
	__weak IBOutlet UITextView *_titleLabel;
	
	__weak IBOutlet UIImageView *_backgroundImageView;
}

@property (nonatomic) BOOL skipBorder;

-(void)setTitle:(NSString *)title;
-(void)setImage:(UIImage *)image;

@end
