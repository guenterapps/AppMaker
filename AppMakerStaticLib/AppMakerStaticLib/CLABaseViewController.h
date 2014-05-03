//
//  CLABaseViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppMaker.h"
#import "CLAAppDataStore.h"
#import "CLAModelProtocols.h"

@interface CLABaseViewController : UIViewController

@property (nonatomic) CLAAppDataStore *store;
@property (nonatomic, weak) AppMaker *appMaker;
@property (nonatomic) CLALocalizedStringsStore *localizedStrings;

-(BOOL)iOS7Running;

/**
 *  Setup navigation bar; right bar button item calls -toggleViewController
 */

-(void)setupNavigationBarWithImage:(UIImage *)image;

/**
 *  Default implementation throws an exception, must be overridden.
 */

-(void)toggleViewController;

/**
 *  Only for table view delegate/datasource controllers
 *
 */

-(void)setupTableView:(UITableView *)tableView withCellIdentifier:(NSString *)identifier;

/**
 *  Common method to push detail view controller
 *
 */

-(void)pushDetailViewControllerForItem:(id <CLAItem>)item;

/**
 *  Common method to create a navigation controller pop button
 */

-(void)setupBackButton;

-(void)setupTitleView;

-(NSArray *)barButtonItemForSelector:(SEL)selector withImage:(UIImage *)image;

@end
