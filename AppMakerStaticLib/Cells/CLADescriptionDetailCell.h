//
//  CLADescriptionDetailCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 08/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLADescriptionDetailCell : UITableViewCell
{
	IBOutlet UIView *_backview;
}

@property (weak, nonatomic) IBOutlet UITextView *titleTextView;

@property (weak, nonatomic) IBOutlet UITextView *detailTextView;

@end
