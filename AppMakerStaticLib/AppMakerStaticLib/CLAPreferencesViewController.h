//
//  CLAPreferencesViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 03/02/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLABaseViewController.h"

@class CLAPreferences, CLALocalizedStringsStore;

@interface CLAPreferencesViewController : CLABaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) CLAPreferences *preferences;
@property (nonatomic) CLALocalizedStringsStore *localizedStrings;

-(UITableView *)tableView;

@end
