//
//  CLAMenuTableViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#define TO_OPEN M_PI
#define TO_CLOSE 0

#import "CLAMenuTableViewController.h"
#import "UIViewController+JASidePanel.h"
#import "JASidePanelController.h"
#import "CLAModelProtocols.h"
#import "CLAMenuTableViewCell.h"
#import "CLACreditsViewController.h"
#import "CLADetailViewController.h"
#import "CLAPreferencesViewController.h"
#import "CLALocalizedStringsStore.h"
#import "CLAPanelViewController.h"
#import "CLAMainTableViewController.h"
#import "CLAQRCodeReaderViewController.h"

NSString *const CLAMenuControllerDidSelectItemNotificationKey	= @"CLAMenuControllerDidSelectItemNotificationKey";
NSString *const CLAMenuControllerSelectedItemKey				= @"CLAMenuControllerSelectedItemKey";
NSString *const CLAMenuControllerSelectedIndexPathKey			= @"CLAMenuControllerSelectedIndexPathKey";


static NSString *const CLAMenuTableViewCellIdentifier = @"CLAMenuTableViewCell";
static NSString *const CLASubMenuTableViewCellIdentifier = @"CLASubMenuTableViewCell";


@interface CLAMenuTableViewController ()
{
	id lastSelectedViewController;
	NSIndexPath *_previousSelection;
	NSString *_lastTopicCode;
	
	UISearchDisplayController *searchController;
	NSIndexPath *_indexPathSelectedFromSearch;
	BOOL _isSearching;

	NSMutableSet *_openParentTopics;

	UIImage *_backgroundImage;

}

-(void)reloadMenuForStoreFetchedData:(NSNotification *)notification;
-(NSArray *)searchBarSpacer;
-(BOOL)useBackgroundImage;

-(NSArray *)buildTopics;
-(BOOL)isParentTopic:(NSIndexPath *)indexPath;
-(BOOL)isSubTopic:(NSIndexPath *)indexPath;

-(void)rotateSubCategoryArrowAtIndexPath:(NSIndexPath *)indexPath WithAngle:(CGFloat)angle;

@end

@implementation CLAMenuTableViewController


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
	
	_openParentTopics = [NSMutableSet set];
	
	BOOL showSearchBar = [[self.store userInterface][CLAAppDataStoreUIShowSearchBar] boolValue];
	
	UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];

	backView.backgroundColor = [self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey];

	[self setupTableView:self.tableView withCellIdentifier:CLAMenuTableViewCellIdentifier];
	[self setupTableView:self.tableView withCellIdentifier:CLASubMenuTableViewCellIdentifier];
	
	if (YES == showSearchBar)
	{
		
		UISearchBar *searchBar	= [[UISearchBar alloc] initWithFrame:CGRectZero];
		
		searchBar.delegate = self;
		
		searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar
															 contentsController:self];
		
		searchController.displaysSearchBarInNavigationBar = YES;

		searchController.navigationItem.rightBarButtonItems	= [self searchBarSpacer];

		self.navigationController.navigationBar.barTintColor = [self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey];
		
		searchBar.barTintColor		= [self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey];
		searchBar.tintColor			= [self.store userInterface][CLAAppDataStoreUIMenuFontColorKey];
		//searchBar.searchBarStyle	= UISearchBarStyleMinimal;
		searchBar.translucent		= NO;
		
		searchController.searchResultsTableView.backgroundColor = [self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey];
		searchController.searchResultsTableView.separatorStyle	= UITableViewCellSeparatorStyleNone;

		[self setupTableView:searchController.searchResultsTableView withCellIdentifier:CLAMainTableViewCellIdentifier];
		[self setupTableView:searchController.searchResultsTableView withCellIdentifier:CLAEventTableViewCellIdentifier];
		
		searchController.searchResultsDataSource = self.appMaker.mainTableViewController;
		searchController.searchResultsDelegate	 = self;
		
		searchController.delegate = self;
		
		if (self.iOS7Running)
			self.edgesForExtendedLayout = UIRectEdgeTop;
	}
	
	if (self.iOS7Running && !showSearchBar)
	{
		self.tableView.contentInset = UIEdgeInsetsMake(20.0, 0., 0., 0.);
	}

	
	if ([self useBackgroundImage])
	{
		UIImage  *backgroundImage = [_backgroundImage resizableImageWithCapInsets:UIEdgeInsetsZero
														  resizingMode:UIImageResizingModeTile];

		self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
	}
	else
	{
		self.tableView.backgroundColor	= [self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey];
		self.tableView.backgroundView	= backView;
	}
	
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.items = [self buildTopics];
	
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
	
	return [self.items count] + 1 + (self.appMaker.useQRReader ? 1 : 0);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	BOOL isSubTopic = [self isSubTopic:indexPath];
	
	if (isSubTopic)
	{
		cell = [tableView dequeueReusableCellWithIdentifier:CLASubMenuTableViewCellIdentifier forIndexPath:indexPath];
	}
	else
	{
		cell = [tableView dequeueReusableCellWithIdentifier:CLAMenuTableViewCellIdentifier forIndexPath:indexPath];
	}
	
	//fixed a strange: the selected cell is covered by the selectedbacgroundview
	//when it's scrolled until disappears and then reappears. This solved...
	[cell setSelected:NO];
	
	NSString *fontName	= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	UIColor	*fontColor	= [self.store userInterface][CLAAppDataStoreUIMenuFontColorKey];
	CGFloat fontSize	= [[self.store userInterface][CLAAppDataStoreUIMenuFontSizeKey] floatValue];
	
//	if (isSubTopic)
//	{
//		fontSize -= 2.;
//	}
	
	UILabel *label		= [cell valueForKey:@"_title"];
	
	if ([self isParentTopic:indexPath])
	{
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[(CLAMenuTableViewCell *)cell subCategoryArrow].hidden = NO;
		[(CLAMenuTableViewCell *)cell subCategoryArrow].tintColor = fontColor;
	}
	else
	{
		[cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
	}
	
	label.font					= [UIFont fontWithName:fontName size:fontSize];
	label.textColor				= fontColor;
	label.highlightedTextColor	= fontColor;
	
	UIView *backGroundview = [[UIView alloc] initWithFrame:CGRectZero];
	[backGroundview setBackgroundColor:[self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey]];
	
	UIView *selectedView = [[UIView alloc] initWithFrame:CGRectZero];
	[selectedView setBackgroundColor:[self.store userInterface][CLAAppDataStoreUIMenuSelectedColorKey]];
	
	if ([self useBackgroundImage])
	{
		[cell setBackgroundColor:[UIColor clearColor]];
	}
	else
	{
		[cell setBackgroundColor:[self.store userInterface][CLAAppDataStoreUIMenuBackgroundColorKey]];
		cell.backgroundView			= backGroundview;
	}

	cell.selectedBackgroundView	= selectedView;

    NSAssert([cell isKindOfClass:[CLAMenuTableViewCell class]], @"Wrong cell class!");
	
	
	if (indexPath.row < [self.items count])
	{
		id <CLATopic> item = [self.items objectAtIndex:indexPath.row];
	
		[(CLAMenuTableViewCell *)cell setTitle:item.title];
	}
	else
	{
		if (indexPath.row == [self.items count] && self.appMaker.useQRReader)
			[(CLAMenuTableViewCell *)cell setTitle:@"QR Reader"];
		else
			[(CLAMenuTableViewCell *)cell setTitle:[self.localizedStrings localizedStringForString:@"Preferences"]];
	}


    return cell;
}

#pragma mark - Delegate Methods

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	if ([self isSubTopic:indexPath])
	{
		return 35.0;
	}
	
	return 44.0;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView)
	{
		_previousSelection = [tableView indexPathForSelectedRow];
		
		if (!_previousSelection)
			_previousSelection = [NSIndexPath indexPathForRow:0 inSection:0];

		//NSAssert(_previousSelection, @"There should always be a selection!");
		
		if (indexPath.row <= (NSInteger)[self.items count] - 1)
		{
			if ([self isParentTopic:indexPath])
			{
				id <CLATopic> selectedTopic = [self.items objectAtIndex:indexPath.row];
				
				NSString *topicCode = [[selectedTopic topicCode] copy];
				
				NSArray *(^subTopicsHandler)(NSString *) = ^NSArray *(NSString *topicCode)
				{
					self.items = [self buildTopics];
					
					NSArray *subTopics		= [self.store topicsWithParentTopicCode:topicCode];
					
					NSMutableArray *indexPaths = [NSMutableArray array];
					
					NSIndexSet *subIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.row + 1, [subTopics count])];
					
					[subIndexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
					 {
						 [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
					 }];
					
					return indexPaths;
					
				};
				
				if ([_openParentTopics containsObject:topicCode])
				{
					[self rotateSubCategoryArrowAtIndexPath:indexPath WithAngle:TO_CLOSE];
					
					NSArray *indexPaths				= subTopicsHandler(topicCode);
					NSIndexPath *selectedIndexPath	= [tableView indexPathForSelectedRow];
					
					if ([indexPaths containsObject:selectedIndexPath])
					{
						[tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
					}
					
					[_openParentTopics removeObject:topicCode];
					[self.tableView deleteRowsAtIndexPaths:subTopicsHandler(topicCode)
											  withRowAnimation:UITableViewRowAnimationRight];
				}
				else
				{
					[_openParentTopics addObject:topicCode];
					
					[self rotateSubCategoryArrowAtIndexPath:indexPath WithAngle:TO_OPEN];
					
					NSArray *indexPaths				= subTopicsHandler(topicCode);
					[self.tableView insertRowsAtIndexPaths:subTopicsHandler(topicCode)
										  withRowAnimation:UITableViewRowAnimationTop];
					
					
					if (![tableView indexPathForSelectedRow])
					{
						NSUInteger lastTopicIndex = [self.items indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
						{
							BOOL found = NO;
							id <CLATopic> _topic = (id <CLATopic>)obj;
							
							if ([_lastTopicCode isEqualToString:[_topic topicCode]])
							{
								found = YES;
							}
							
							return found;
						}];
						
						if (NSNotFound != lastTopicIndex)
						{
							NSIndexPath *lastTopicIndexPath = [NSIndexPath indexPathForRow:lastTopicIndex inSection:0];
							
							if ([indexPaths containsObject:lastTopicIndexPath])
							{
								dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
									[tableView selectRowAtIndexPath:lastTopicIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
								});
								
							}
						}
					}

				}
				
				return nil;
			}
			
			if (![self.delegate menuViewControllerShouldSelectTopic:[self.items objectAtIndex:indexPath.row]])
			{
				return _previousSelection;
			}
		}
	}
	
	return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView != self.tableView)
	{
		_indexPathSelectedFromSearch = indexPath;
		_isSearching = NO;
		
		[searchController setActive:NO animated:YES];
		
		[UIView animateWithDuration:0.2 animations:^()
		 {
			 self.searchDisplayController.navigationItem.rightBarButtonItems = [self searchBarSpacer];
		 }];
		
		return;
	}
	
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
	else
	{
		if (indexPath.row == [self.items count] && self.appMaker.useQRReader)
		{
			UINavigationController *navController = (UINavigationController *)self.sidePanelController.centerPanel;
			
			if (!lastSelectedViewController)
			{
				lastSelectedViewController = self.appMaker.mainTableViewController;
			}
			
			CLAQRCodeReaderViewController *qrReader = [[CLAQRCodeReaderViewController alloc] init];
			qrReader.appMaker = self.appMaker;
			qrReader.store	= self.store;
			[navController setViewControllers:@[qrReader]];
		}
		else
		{
			UINavigationController *navController = (UINavigationController *)self.sidePanelController.centerPanel;
			
			if (!lastSelectedViewController)
			{
				lastSelectedViewController = self.appMaker.mainTableViewController;
			}
			
			[navController setViewControllers:@[self.appMaker.preferencesViewController]];
		}
	}
	
	[self.sidePanelController toggleLeftPanel:self];
}

#pragma mark - Private Methods

-(void)rotateSubCategoryArrowAtIndexPath:(NSIndexPath *)indexPath WithAngle:(CGFloat)angle
{
	NSParameterAssert(indexPath);
	
	CLAMenuTableViewCell *cell = (CLAMenuTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	
	NSAssert(cell, @"Must return a valid cell");
	
	[UIView beginAnimations:@"subCategoryArrow" context:NULL];
	
	cell.subCategoryArrow.transform = CGAffineTransformMakeRotation(angle);
	
	[UIView commitAnimations];
	
}


-(BOOL)isParentTopic:(NSIndexPath *)indexPath
{
	BOOL isParent = NO;
	
	if (indexPath.row <= (NSInteger)[self.items count] - 1)
	{
		id <CLATopic> selectedTopic = [self.items objectAtIndex:indexPath.row];
		
		isParent = [[selectedTopic childTopics] count] > 0;
		
	}
	
	return isParent;
}

-(BOOL)isSubTopic:(NSIndexPath *)indexPath
{
	BOOL isParent = NO;
	
	if (indexPath.row <= (NSInteger)[self.items count] - 1)
	{
		id <CLATopic> selectedTopic = [self.items objectAtIndex:indexPath.row];
		
		isParent = [selectedTopic parentTopic] != nil;
		
	}
	
	return isParent;
}

-(NSArray *)buildTopics
{
	NSMutableArray *collectedTopics = [NSMutableArray arrayWithArray:[[self.store mainTopics] copy]];
	
	NSUInteger menuIndexShift = 0;
	
	for (id <CLATopic> parentTopic in [self.store topicsFromTopicsCodes:[_openParentTopics copy]])
	{
		NSAssert(parentTopic, @"topic code should be a NSString");

		NSUInteger index = [[self.store mainTopics] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
		{
			BOOL found = NO;
			id <CLATopic> topic = (id <CLATopic>)obj;
			
			if ([[topic topicCode] isEqualToString:[parentTopic topicCode]])
				found = YES;

			return found;
			
		}];
		
		if (NSNotFound == index)
		{
			[_openParentTopics removeObject:[parentTopic topicCode]];
		}
		else
		{
			NSArray *childTopics		= [self.store topicsWithParentTopicCode:[parentTopic topicCode]];
			
			NSAssert([childTopics count] > 0, @"should have child topics");
			
			NSIndexSet *childIndexSet	= [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(index + 1 + menuIndexShift, [childTopics count])];
	
			menuIndexShift += [childTopics count];
			[collectedTopics insertObjects:childTopics atIndexes:childIndexSet];
		}
	}
	
	return [NSArray arrayWithArray:collectedTopics];
}

-(BOOL)useBackgroundImage
{
	_backgroundImage = [UIImage imageNamed:@"menuBackground"];
	
	return _backgroundImage != nil;

}

-(NSArray *)searchBarSpacer
{
	
	UIBarButtonItem *dummyButton	= [[UIBarButtonItem alloc] initWithCustomView:[UIView new]];
	UIBarButtonItem *fixedSpace		= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL];
	
	fixedSpace.width = 38.;

	return @[fixedSpace, dummyButton];
}

-(void)reloadMenuForStoreFetchedData:(NSNotification *)notification
{
	self.items = [self buildTopics];

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

#pragma mark UISearchDisplayDelegate

-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	[UIView animateWithDuration:0.2
					 animations:^()
	{
		self.searchDisplayController.navigationItem.rightBarButtonItems = nil;
		CLAPanelViewController *panel = (CLAPanelViewController *)self.appMaker.rootViewController;
		
		[panel setCenterPanelHidden:YES];

	}];

}


-(void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
	[UIView animateWithDuration:0.2
					 animations:^()
	{
		//self.searchDisplayController.navigationItem.rightBarButtonItems = [self searchBarSpacer];

		CLAPanelViewController *panel = (CLAPanelViewController *)self.appMaker.rootViewController;
		
		[panel setCenterPanelHidden:NO];

	}
					 completion:^(BOOL finished)
	{
		if (_indexPathSelectedFromSearch)
		{
			UINavigationController *navController = (UINavigationController *)self.sidePanelController.centerPanel;

			id <CLAItem> item = self.appMaker.mainTableViewController.searchControllerItems[_indexPathSelectedFromSearch.row];

			CLADetailViewController *detailVC = [[CLADetailViewController alloc] initWithItem:item];

			[navController setViewControllers:@[detailVC]];

			detailVC.store		= self.store;
			detailVC.appMaker	= self.appMaker;
			detailVC.skipList	= YES;
			detailVC.localizedStrings = self.localizedStrings;

			[self.sidePanelController toggleLeftPanel:self];

		}
		 
		_indexPathSelectedFromSearch = nil;
	 }];

}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	if ([searchString length] > 0)
	{
		[self.appMaker.mainTableViewController setQueryString:searchString];
		
		return _isSearching = YES;
	}
	
	return _isSearching = NO;
}

#pragma mark - UISearchBarDelegate

-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	[self.searchDisplayController setActive:YES animated:YES];

	return YES;
}

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
	if (!_isSearching)
	{
		[UIView animateWithDuration:0.2 animations:^()
		 {
			 self.searchDisplayController.navigationItem.rightBarButtonItems = [self searchBarSpacer];
		 }];
	}
	
	return YES;
}

@end
