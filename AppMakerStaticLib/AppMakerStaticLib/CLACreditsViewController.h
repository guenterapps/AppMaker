//
//  CLACreditsViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 29/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLABaseViewController.h"

@interface CLACreditsViewController : CLABaseViewController <UITableViewDataSource, UITableViewDelegate>

-(UITableView *)tableView;

@end
