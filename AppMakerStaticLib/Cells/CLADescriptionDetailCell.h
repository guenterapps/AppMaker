//
//  CLADescriptionDetailCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 08/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLATableViewCellConfigurationProtocol.h"

@interface CLADescriptionDetailCell : UITableViewCell <CLATableViewCellConfigurationProtocol>
{
	IBOutlet UIView *_backview;
}

@property (weak, nonatomic) IBOutlet UITextView *titleTextView;

@property (weak, nonatomic) IBOutlet UITextView *detailTextView;

@end
