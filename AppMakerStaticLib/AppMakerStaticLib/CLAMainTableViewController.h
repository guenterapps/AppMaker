//
//  CLAMainTableViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLABaseViewController.h"
#import "CLAModelProtocols.h"
#import "UIScrollView+SVPullToRefresh.h"

@interface CLAMainTableViewController : CLABaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSArray *items;
@property (nonatomic) id <CLATopic>topic;

@property (nonatomic) BOOL skipAnimation;

-(UITableView *)tableView;

@end
