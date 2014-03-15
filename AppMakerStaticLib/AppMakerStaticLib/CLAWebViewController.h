//
//  CLAWebViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 23/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLABaseViewController.h"
#import "CLAModelProtocols.h"

@interface CLAWebViewController : CLABaseViewController

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic) NSString *headerTitle;
@property (nonatomic) id <CLAItem> item;

@end
