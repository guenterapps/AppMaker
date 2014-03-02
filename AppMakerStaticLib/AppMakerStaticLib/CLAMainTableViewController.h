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

extern NSString *const CLAMainTableViewCellIdentifier;
extern NSString *const CLAEventTableViewCellIdentifier;

@interface CLAMainTableViewController : CLABaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSArray *items;
@property (nonatomic) NSArray *searchControllerItems;
@property (nonatomic) id <CLATopic>topic;

@property (nonatomic) BOOL skipAnimation;

@property (nonatomic) NSString *queryString;

-(UITableView *)tableView;

@end
