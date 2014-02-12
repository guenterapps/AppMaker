//
//  CLAEventTableViewCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 12/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLAEventTableViewCell : UITableViewCell
{
	
	__weak IBOutlet UIImageView *_itemImageView;
	__weak IBOutlet UITextView *_titleLabel;
	
	__weak IBOutlet UIImageView *_backgroundImageView;
}
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;

-(void)setTitle:(NSString *)title;
-(void)setImage:(UIImage *)image;
@end
