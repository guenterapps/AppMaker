//
//  CLAWebPlayerController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAWebPlayerController.h"

@interface CLAWebPlayerController ()

@end

@implementation CLAWebPlayerController

-(UIWebView *)webView
{
	return (UIWebView *)self.view;
}

-(NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

@end
