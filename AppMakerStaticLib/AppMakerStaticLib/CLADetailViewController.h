//
//  CLADetailViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "CLABaseViewController.h"
#import "CLAModelProtocols.h"
#import "CLALocalizedStringsStore.h"

@interface CLADetailViewController : CLABaseViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate, UIWebViewDelegate>

@property (nonatomic) CLALocalizedStringsStore *localizedStrings;

@property (nonatomic) id <CLAItem> item;
@property (nonatomic) BOOL skipList;

-(id)initWithItem:(id <CLAItem>)item;

-(UITableView *)tableView;


@end
