//
//  CLAPanelViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAPanelViewController.h"

@interface CLAPanelViewController ()

-(NSArray *)leftButtonArrayForCenterPanel;

@end


@implementation CLAPanelViewController

- (void)stylePanel:(UIView *)panel {
    //panel.layer.cornerRadius = 6.0f;
    panel.clipsToBounds = YES;
}

- (UIBarButtonItem *)leftButtonForCenterPanel
{
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];

	UIImage *menu = [self.store userInterface][CLAAppDataStoreUIMenuIconKey];
	[button setImage:menu forState:UIControlStateNormal];
	[button addTarget:self action:@selector(toggleLeftPanel:) forControlEvents:UIControlEventTouchUpInside];
	
	return [[UIBarButtonItem alloc] initWithCustomView:button];
}

//needed to fix button misplacement in ios7
- (void)_placeButtonForLeftPanel {
    if (self.leftPanel) {
        UIViewController *buttonController = self.centerPanel;
        if ([buttonController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)buttonController;
            if ([nav.viewControllers count] > 0) {
                buttonController = [nav.viewControllers objectAtIndex:0];
            }
        }
        if (!buttonController.navigationItem.leftBarButtonItem) {
            buttonController.navigationItem.leftBarButtonItems = [self leftButtonArrayForCenterPanel];
        }
    }
}

-(NSArray *)leftButtonArrayForCenterPanel
{
	NSArray *buttonsArray;
	UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	spacer.width = -10;
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)
	{
		buttonsArray = @[spacer, [self leftButtonForCenterPanel]];
	}
	else
	{
		buttonsArray = @[[self leftButtonForCenterPanel]];
	}
	
	return buttonsArray;
}

-(NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

@end
