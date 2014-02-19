//
//  CLAActionsDetailCell.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 08/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLATableViewCellConfigurationProtocol.h"

@interface CLAActionsDetailCell : UITableViewCell <CLATableViewCellConfigurationProtocol>
{
	
	__weak IBOutlet UIView *_backView;
}

@property (weak, nonatomic) IBOutlet UIButton *phoneButton;
@property (weak, nonatomic) IBOutlet UIButton *mailButton;


-(void)setBackviewColor:(UIColor *)color;


@end
