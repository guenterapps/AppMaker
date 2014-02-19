//
//  CLAHeaderDetailCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLATableViewCellConfigurationProtocol.h"

@interface CLAHeaderDetailCell : UITableViewCell <CLATableViewCellConfigurationProtocol>
{
	__weak IBOutlet UILabel *_titleLabel;
	
	__weak IBOutlet UIImageView *_backgroundImageView;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

-(void)setTitle:(NSString *)title;

@end
