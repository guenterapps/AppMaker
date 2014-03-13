//
//  CLAMenuTableViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLABaseViewController.h"
#import "CLAMenuViewControllerDelegate.h"

@class CLALocalizedStringsStore;

@interface CLAMenuTableViewController : CLABaseViewController <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic) CLALocalizedStringsStore *localizedStrings;

@property (nonatomic) NSArray *items;
@property (nonatomic, weak) id <CLAMenuViewControllerDelegate> delegate;

-(UITableView *)tableView;


@end
