//
//  CLAMenuTableViewCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLAMenuTableViewCell : UITableViewCell
{
	
	__weak IBOutlet UILabel *_title;
}

@property (weak, nonatomic) IBOutlet UIImageView *subCategoryArrow;
-(void)setTitle:(NSString *)title;

@end
