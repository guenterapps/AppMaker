//
//  CLAWebViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 23/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAWebViewController.h"


@interface CLAWebViewController ()

@end

@implementation CLAWebViewController

-(void)loadView
{
	self.view = [[UIWebView alloc] initWithFrame:CGRectZero];
}

-(UIWebView *)webView
{
	return (UIWebView *)self.view;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	[self setupBackButton];
	[self setupTitleView];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[(UILabel *)self.navigationItem.titleView setText:[self.item title]];
}

@end
