//
//  CLAMainTableViewCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 05/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLAMainTableViewCell : UITableViewCell
{
	
	__weak IBOutlet UIImageView *_itemImageView;
	__weak IBOutlet UITextView *_titleLabel;
	
	__weak IBOutlet UIImageView *_backgroundImageView;
}

-(void)setTitle:(NSString *)title;
-(void)setImage:(UIImage *)image;

@end
