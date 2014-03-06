//
//  CLAMenuTableViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAMenuTableViewController.h"
#import "UIViewController+JASidePanel.h"
#import "JASidePanelController.h"
#import "CLAModelProtocols.h"
#import "CLAMenuTableViewCell.h"
#import "CLACreditsViewController.h"
#import "CLADetailViewController.h"
#import "CLAPreferencesViewController.h"
#import "CLALocalizedStringsStore.h"

NSString *const CLAMenuControllerDidSelectItemNotificationKey	= @"CLAMenuControllerDidSelectItemNotificationKey";
NSString *const CLAMenuControllerSelectedItemKey				= @"CLAMenuControllerSelectedItemKey";
NSString *const CLAMenuControllerSelectedIndexPathKey			= @"CLAMenuControllerSelectedIndexPathKey";


static NSString *const CLAMenuTableViewCellIdentifier = @"CLAMenuTableViewCell";

@interface CLAMenuTableViewController ()
{
	id lastSelectedViewController;
	NSIndexPath *_previousSelection;
	NSString *_lastTopicCode;
}

-(void)reloadMenuForStoreFetchedData:(NSNotification *)notification;

@end

@implementation CLAMenuTableViewController

-(void)setItems:(NSArray *)items
{
	
	_items = [items sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
	{
		id <CLATopic>topic1 = (id <CLATopic>)obj1;
		id <CLATopic>topic2	= (id <CLATopic>)obj2;
		
		
		NSComparisonResult result = NSOrderedSame;
		
		if (NSOrderedSame == [@"credits" caseInsensitiveCompare:topic1.title])
		{
			result = NSOrderedDescending;
		}
		else if (NSOrderedSame == [@"credits" caseInsensitiveCompare:topic2.title])
		{
			result = NSOrderedAscending;
		}
		
		return result;
		
	}];

}

-(UITableView *)tableView
{
	return (UITableView *)self.view;
}

-(void)loadView
{
	self.view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (self.iOS7Running)
	{
		self.tableView.contentInset = UIEdgeInsetsMake(20.0, 0., 0., 0.);
	}

	self.tableView.backgroundColor = [self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey];
	[self setupTableView:self.tableView withCellIdentifier:CLAMenuTableViewCellIdentifier];

}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.items = [self.store.topics copy];
	
//	if (!_previousSelection)
//	{
//		if ([self.tableView numberOfRowsInSection:0] > 0)
//		{
//			_previousSelection = [NSIndexPath indexPathForItem:0 inSection:0];
//			_lastTopicCode = [[[self.items objectAtIndex:0] topicCode] copy];
//			[self.tableView selectRowAtIndexPath:_previousSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
//		}
//
//	}
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self];
	
	[notificationCenter addObserver:self
						   selector:@selector(reloadMenuForStoreFetchedData:)
							   name:CLAAppDataStoreDidFetchNewData
							 object:self.store];
	
	[notificationCenter addObserver:self
						   selector:@selector(reloadMenuForStoreFetchedData:)
							   name:CLAAppDataStoreDidFailToFetchNewData
							 object:self.store];
	[notificationCenter addObserver:self
						   selector:@selector(reloadMenuForStoreFetchedData:)
							   name:CLAAppDataStoreDidInvalidateCache
							 object:self.store];
}

-(void)viewDidAppear:(BOOL)animated
{
	if (!_previousSelection)
	{
		_previousSelection = [NSIndexPath indexPathForItem:0 inSection:0];
		[self.tableView selectRowAtIndexPath:_previousSelection animated:NO scrollPosition:UITableViewScrollPositionNone];

		if ([self.tableView numberOfRowsInSection:0] > 2)
			_lastTopicCode = [[[self.items objectAtIndex:0] topicCode] copy];
		
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Datasource Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.items count] + 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CLAMenuTableViewCellIdentifier forIndexPath:indexPath];

    NSAssert([cell isKindOfClass:[CLAMenuTableViewCell class]], @"Wrong cell class!");
	
	if (indexPath.row < [self.items count])
	{
		id <CLATopic> item = [self.items objectAtIndex:indexPath.row];
	
		[(CLAMenuTableViewCell *)cell setTitle:item.title];
	}
	else //if (indexPath.row == [self.items count])
	{
		[(CLAMenuTableViewCell *)cell setTitle:[self.localizedStrings localizedStringForString:@"Preferences"]];
	}
//	else
//		[(CLAMenuTableViewCell *)cell setTitle:@"CREDITS"];

    return cell;
}

#pragma mark - Delegate Methods

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *fontName	= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	UIColor	*fontColor	= [self.store userInterface][CLAAppDataStoreUIMenuFontColorKey];
	CGFloat fontSize	= [[self.store userInterface][CLAAppDataStoreUIMenuFontSizeKey] floatValue];
	UILabel *label		= [cell valueForKey:@"_title"];
	
	label.font			= [UIFont fontWithName:fontName size:fontSize];
	label.textColor		= fontColor;
	
	UIView *backGroundview = [[UIView alloc] initWithFrame:CGRectZero];
	[backGroundview setBackgroundColor:[self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey]];
	
	UIView *selectedView = [[UIView alloc] initWithFrame:CGRectZero];
	[selectedView setBackgroundColor:[self.store userInterface][CLAAppDataStoreUIMenuSelectedColorKey]];

	cell.backgroundView			= backGroundview;
	cell.selectedBackgroundView	= selectedView;

}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	_previousSelection = [tableView indexPathForSelectedRow];
	
	NSAssert(_previousSelection, @"There should always be a selection!");
	
	if (indexPath.row < (NSInteger)[self.items count] - 1)
	{
		if (![self.delegate menuViewControllerShouldSelectTopic:[self.items objectAtIndex:indexPath.row]])
		{
			return _previousSelection;
		}
	}
	
	return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	if (indexPath.row < [self.items count])
	{
		UINavigationController *navController = (UINavigationController *)self.sidePanelController.centerPanel;
		
		id <CLATopic> topic = [self.items objectAtIndex:indexPath.row];
		_lastTopicCode = [[topic topicCode] copy];
		
		if ([[topic items] count] == 1)
		{
			CLADetailViewController *detailVC = [[CLADetailViewController alloc] initWithItem:[[topic items] anyObject]];
						
			[navController setViewControllers:@[detailVC]];

			detailVC.store		= self.store;
			detailVC.appMaker	= self.appMaker;
			detailVC.skipList	= YES;
			detailVC.localizedStrings = self.localizedStrings;

		}
		else if (lastSelectedViewController)
		{
			[navController setViewControllers:@[lastSelectedViewController]];
			lastSelectedViewController = nil;
		}
		else if ([navController.viewControllers[0] isKindOfClass:[CLADetailViewController class]])
		{
			[navController setViewControllers:@[self.appMaker.mainTableViewController]];

		}
		

		NSDictionary *userInfo = @{CLAMenuControllerSelectedIndexPathKey: indexPath,
								   CLAMenuControllerSelectedItemKey: topic};
		
		[[NSNotificationCenter defaultCenter] postNotificationName:CLAMenuControllerDidSelectItemNotificationKey
															object:self
														userInfo:userInfo];		
	}
	else if (indexPath.row == [self.items count])
	{
		UINavigationController *navController = (UINavigationController *)self.sidePanelController.centerPanel;
		
		if (!lastSelectedViewController)
		{
			lastSelectedViewController = self.appMaker.mainTableViewController;
		}
		
		[navController setViewControllers:@[self.appMaker.preferencesViewController]];
	}
	else
	{
		UINavigationController *navController = (UINavigationController *)self.sidePanelController.centerPanel;
		
		if (!lastSelectedViewController)
		{
			lastSelectedViewController = self.appMaker.mainTableViewController;
		}
		
		[navController setViewControllers:@[self.appMaker.creditsViewController]];
	}
	
	[self.sidePanelController toggleLeftPanel:self];
}

#pragma mark - Private Methods

-(void)reloadMenuForStoreFetchedData:(NSNotification *)notification
{
	self.items = [self.store.topics copy];
	
	NSIndexPath *indexPathToSelect;
	
	if ([self.items count] > 0)
	{
		NSInteger selection = [self.items indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
		{
			id <CLATopic> topic = (id <CLATopic>)obj;
			
			if ([[topic topicCode] isEqualToString:_lastTopicCode])
				return YES;
			
			return NO;

		}];
		
		if (selection != NSNotFound)
		{
			indexPathToSelect = [NSIndexPath indexPathForItem:selection inSection:0];
		}
	}
	
	if (!indexPathToSelect)
			indexPathToSelect = [NSIndexPath indexPathForItem:0 inSection:0];

	[self.tableView reloadData];

	double delayInSeconds = 0.2;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		if (indexPathToSelect)
		{
			[self.tableView selectRowAtIndexPath:indexPathToSelect animated:YES scrollPosition:UITableViewScrollPositionNone];
		}

	});

}

@end
