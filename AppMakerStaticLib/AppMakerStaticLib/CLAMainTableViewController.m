//
//  CLAMainTableViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#define TIMEOUT 10.0

#import <CoreLocation/CoreLocation.h>

#import "CLAMainTableViewController.h"
#import "CLAMapViewController.h"
#import "CLAMainTableViewCell.h"
#import "CLAMenuTableViewController.h"
#import "CLADetailViewController.h"
#import "CLAEventTableViewCell.h"
#import "Item.h"
#import "Topic.h"
#import "UITableViewCell+Common.h"
#import "SVProgressHUD.h"

NSString *const CLAMainTableViewCellIdentifier = @"CLAMainTableViewCell";
NSString *const CLAEventTableViewCellIdentifier = @"CLAEventTableViewCell";

@interface CLAMainTableViewController ()
{
	CGFloat _scrolledHeight;
	
}

@property (nonatomic) NSString *lastTopicCode;


-(void)reloadContentsForNewTopic:(NSNotification *)notification;

-(void)reloadContentsForStoreFetchedData:(NSNotification *)notification;
-(void)setItems:(NSArray *)items;
-(void)callApi:(NSNotification *)notification;
-(UIImage *)mainImageForItem:(id <CLAItem>)item onCell:(UITableViewCell *)cell;

@end

@implementation CLAMainTableViewController

@synthesize topic = _topic;

-(id)init
{
	if (self = [super init])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reloadContentsForNewTopic:)
													 name:CLAMenuControllerDidSelectItemNotificationKey
												   object:nil];
	}
	
	return self;
}

//-(void)setItems:(NSArray *)items
//{
//	if ([ORDERBY_POSITION isEqualToString:[(Topic *)self.topic sortOrder]])
//	{
//		items	= [items sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
//		{
//			Item *item1	= (Item *)obj1;
//			Item *item2	= (Item *)obj2;
//
//			CLLocation *location1 = [[CLLocation alloc] initWithLatitude:[[item1 latitude] doubleValue] longitude:[[item1 longitude] doubleValue]];
//
//			CLLocation *location2 = [[CLLocation alloc] initWithLatitude:[[item2 latitude] doubleValue] longitude:[[item2 longitude] doubleValue]];
//
//			CLLocationDistance distance1 = [location1 distanceFromLocation:self.store.lastPosition];
//			CLLocationDistance distance2 = [location2 distanceFromLocation:self.store.lastPosition];
//
//			NSComparisonResult result;
//
//			if (distance1 > distance2)
//				result = NSOrderedDescending;
//			else if (distance2 > distance1)
//				result = NSOrderedAscending;
//			else
//				result = NSOrderedSame;
//
//			return result;
//		}];
//	}
//	
//	_items = items;
//}


-(void)setTopic:(id<CLATopic>)topic
{
	//NSParameterAssert(topic);
	
	BOOL topicHasChanged = ![[topic topicCode] isEqualToString:self.lastTopicCode];
	
	_topic = topic;
	
	self.lastTopicCode	= [[topic topicCode] copy];
	self.items			= [[self.store contentsForTopic:topic] copy];

	[(UILabel *)self.navigationItem.titleView setText:[topic title]];
	
	if ([[self.store poisForTopic:self.topic] count] > 0)
	{
		UIImage *pin = [self.store userInterface][CLAAppDataStoreUIMapIconKey];
		[self setupNavigationBarWithImage:pin];
	}
	else
	{
		self.navigationItem.rightBarButtonItems = nil;
	}
	
	[self.tableView reloadData];
	
	if (topicHasChanged && _topic)
	{
		_scrolledHeight		= self.tableView.frame.size.height;
		
		if ([self.items count] > 0 )
		{

			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
								  atScrollPosition:UITableViewScrollPositionTop
										  animated:NO];

		}
	}
}

-(void)toggleViewController
{
	CLAMapViewController *mapViewController = self.appMaker.mapViewController;

	mapViewController.topic = self.topic;
	
	[UIView transitionFromView:self.view toView:mapViewController.view
					  duration:0.30
					   options:UIViewAnimationOptionTransitionFlipFromLeft
					completion:^(BOOL finished)
	 {
		 
		 [self.navigationController setViewControllers:@[mapViewController]];
		 
	 }];
}


#pragma mark - View-related methods

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
	
	[self.view setBackgroundColor:[UIColor clearColor]];
	
	[self setupTableView:self.tableView withCellIdentifier:CLAMainTableViewCellIdentifier];
	[self setupTableView:self.tableView withCellIdentifier:CLAEventTableViewCellIdentifier];
	
	[self setupPullToRefresh];

	[self setupTitleView];

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (!_scrolledHeight)
	{
		_scrolledHeight	= self.tableView.frame.size.height;
	}
	
	UIStatusBarStyle style = [[self.store userInterface][CLAAppDataStoreUIStatusBarStyleKey] integerValue];
	
	NSAssert(style >= 0 && style <= 1, @"Invalid status bar style %d", style);
	
	[[UIApplication sharedApplication] setStatusBarStyle:style];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	
	[self setNeedsStatusBarAppearanceUpdate];
	
	self.items = [[self.store contentsForTopic:self.topic] copy];

	[(UILabel *)self.navigationItem.titleView setText:[self.topic title]];

//	[notificationCenter addObserver:self
//						   selector:@selector(reloadContentsForStoreFetchedData:)
//							   name:CLAAppDataStoreDidFetchNewData
//							 object:self.store];
//
//	[notificationCenter addObserver:self
//						   selector:@selector(reloadContentsForStoreFetchedData:)
//							   name:CLAAppDataStoreDidFailToFetchNewData
//							 object:self.store];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
//	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tableView)
	{
		return self.items.count;
	}

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"title", self.queryString];
	
	self.searchControllerItems = [[self.store contents] filteredArrayUsingPredicate:predicate];
	
	return [self.searchControllerItems count];
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	id <CLAItem> item;
    
	if (tableView == self.tableView)
	{
		item = [self.items objectAtIndex:indexPath.row];
	}
	else
    {
		item = [self.searchControllerItems objectAtIndex:indexPath.row];
	}
	
	if ([item.subType isEqualToString:@"event"])
	{
		static NSDateFormatter *dayFormatter;
		static NSDateFormatter *monthFormatter;
		
		if (!dayFormatter)
		{
			dayFormatter = [[NSDateFormatter alloc] init];
			[dayFormatter setDateFormat:@"dd"];
		}
		
		if (!monthFormatter)
		{
			monthFormatter = [[NSDateFormatter alloc] init];
			[monthFormatter setDateFormat:@"MMM"];
		}
		
		CLAEventTableViewCell *eventCell = (CLAEventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CLAEventTableViewCellIdentifier forIndexPath:indexPath];

		NSString *fontName		= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
		
		eventCell.monthLabel.font		= [UIFont fontWithName:fontName size:16.0];
		eventCell.monthLabel.textColor	= [self.store userInterface][CLAAppDataStoreUIMainListFontColorKey];
		
		eventCell.dayLabel.font		= [UIFont fontWithName:fontName size:18.0];
		eventCell.dayLabel.textColor	= [self.store userInterface][CLAAppDataStoreUIMainListFontColorKey];
		
		[eventCell setTitle:item.title];
		[eventCell setImage:[self mainImageForItem:item onCell:eventCell]];

		
		eventCell.monthLabel.text = [[monthFormatter stringFromDate:item.date] uppercaseString];
		eventCell.dayLabel.text = [dayFormatter stringFromDate:item.date];
		
		cell = (UITableViewCell *)eventCell;
	}
	else
	{
		CLAMainTableViewCell *mainCell = (CLAMainTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CLAMainTableViewCellIdentifier forIndexPath:indexPath];
		
		[mainCell setTitle:item.title];
		
		[mainCell setImage:[self mainImageForItem:item onCell:mainCell]];
		
		cell = (UITableViewCell *)mainCell;
	}
	
	UILabel     *titleLabel			= [cell valueForKey:@"_titleLabel"];
	
	NSString *fontName		= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	CGFloat fontSize		= [[self.store userInterface][CLAAppDataStoreUIMainListFontSizeKey] floatValue];
	
	titleLabel.font			= [UIFont fontWithName:fontName size:fontSize];
	titleLabel.textColor	= [self.store userInterface][CLAAppDataStoreUIMainListFontColorKey];
	NSUInteger shadowMask = (NSUInteger)[[self.store userInterface][CLAAppDataStoreUICellShadowBitMaskKey] integerValue];

	if (shadowMask & CLACellShadowMaskMainCell)
		[cell setShadowColor:(UIColor *)[self.store userInterface][CLAAppDataStoreUICellShadowColorKey]];

    return cell;

}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self pushDetailViewControllerForItem:self.items[indexPath.row]];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{

	if (cell.frame.origin.y <= _scrolledHeight || self.skipAnimation)
	{
		return;
	}
	else if (cell.frame.origin.y > _scrolledHeight)
	{
		_scrolledHeight = cell.frame.origin.y;
	}
	
	CGRect finalRect = cell.frame;
	
	CAAnimationGroup *completeAnimation = [CAAnimationGroup animation];
	
	CATransform3D translation = CATransform3DIdentity;
	
	translation.m34 = -1./500.;
	
	cell.superview.layer.sublayerTransform =  translation;
	cell.layer.anchorPoint	= CGPointMake(1., 1.);
	
	CABasicAnimation *moveRight 		= [CABasicAnimation animation];
	
	[moveRight setKeyPath:@"transform.translation.x"];
	[moveRight setFromValue:@(-50)];
	[moveRight setToValue:@(0)];
	
	CABasicAnimation *moveUp			= [CABasicAnimation animation];
	
	[moveUp setKeyPath:@"transform.translation.y"];
	[moveUp setFromValue:@(150)];
	[moveUp setToValue:@(0)];
	
	CABasicAnimation *dropDown = [CABasicAnimation animation];

	[dropDown setKeyPath:@"transform.translation.z"];
	[dropDown setFromValue:@(150)];
	[dropDown setToValue:@(0)];
	
	CABasicAnimation *rotate = [CABasicAnimation animation];
	
	[rotate setKeyPath:@"transform.rotation"];
	[rotate setFromValue:@(-(M_PI_2 / 8.))];
	[rotate setToValue:@(0)];
	
	[completeAnimation setAnimations:@[rotate, moveUp, moveRight, dropDown]];
	[completeAnimation setDuration:0.5];
	[completeAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	
	[cell.layer addAnimation:completeAnimation forKey:nil];
	
	cell.frame = finalRect;

}

#pragma mark - Private Methods

-(UIImage *)mainImageForItem:(id <CLAItem>)item onCell:(UITableViewCell *)cell;
{
	NSParameterAssert(item);
	
	UIImage *mainImage = [item mainImage];
	
	if (!mainImage)
	{

		[self.store fetchMainImageForItem:item completionBlock:^(NSError *error)
		{
			if (![item mainImage])
				return;
			
			NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
			
			if (cellIndexPath && (cellIndexPath.row < [self.items count]))
			{
				id <CLAItem> cellItem = [self.items objectAtIndex:cellIndexPath.row];
				
				if ([cellItem isEqual:item])
				{
					CATransition *fade = [CATransition animation];
					
					[fade setType:kCATransitionFade];
					
					[cell.layer addAnimation:fade forKey:nil];
					
					[(CLAMainTableViewCell *)cell setImage:[item mainImage]];
				}
			}
			
		}];
	
		return [UIImage imageNamed:@"noImage"];
	}
	
	return mainImage;
}


#pragma mark Data handling

-(void)reloadContentsForStoreFetchedData:(NSNotification *)notification
{
	
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CLAAppDataStoreDidFailToFetchNewData object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CLAAppDataStoreDidFetchNewData object:nil];
	
	NSError *error = [notification userInfo][CLAAppDataStoreFetchErrorKey];
	
	if (error)
	{
		if ([SVProgressHUD isVisible])
		{
			[SVProgressHUD dismiss];
		}

		NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento dei dati! (Code: %li)", (long)error.code];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errore!"
														message:alertMessage
													   delegate:nil
											  cancelButtonTitle:@"Continua"
											  otherButtonTitles:nil];
		[alert show];
		
		return;

	}
	
	[self.store preFetchMainImagesWithCompletionBlock:^(NSError *error)
	 {
		 if (error)
		 {
			 NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento delle immagini! (Code: %li)", (long)error.code];
			 
			 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errore!"
																 message:alertMessage
																delegate:nil
													   cancelButtonTitle:@"Continua"
													   otherButtonTitles:nil];
			 [alertView show];
		 }
		 
		 [self.tableView.pullToRefreshView stopAnimating];
		 
		 if ([SVProgressHUD isVisible])
		 {
			 [SVProgressHUD dismiss];
		 }
		 
		 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"topicCode == %@", self.lastTopicCode];
		 
		 self.items	= nil;
		 
		 _topic		=  [[self.store.topics filteredArrayUsingPredicate:predicate] lastObject];
		 
		 if (_topic)
		 {
			 [self reloadContentsForTopic:_topic];
		 }
		 else
			 [self.tableView reloadData];

	 }];

}

- (void)reloadContentsForTopic:(id)topic
{
	NSParameterAssert(topic);
	
	self.topic = topic;

}

-(void)reloadContentsForNewTopic:(NSNotification *)notification
{
//	if (!self.navigationController)
//	{
//		return;
//	}
	
	id <CLATopic> topic = [[notification userInfo] objectForKey:CLAMenuControllerSelectedItemKey];

	[self reloadContentsForTopic:topic];
}

- (void)setupPullToRefresh
{
	
	[self.tableView addPullToRefreshWithActionHandler:^()
	 {
		 [[NSNotificationCenter defaultCenter] addObserver:self
												  selector:@selector(callApi:)
													  name:CLAAppDataStoreDidStopSeachingPosition
													object:self.store];
		 
		 NSString *loading = [self.localizedStrings localizedStringForString:@"Loading..."];
		 
		 [SVProgressHUD showWithStatus:loading maskType:SVProgressHUDMaskTypeGradient];
		 
		 [self.store startUpdatingLocation];
	 }];
	
	[self.tableView.pullToRefreshView setTitle:[self.localizedStrings localizedStringForString:@"Loading..."]
									  forState:SVPullToRefreshStateLoading];

	[self.tableView.pullToRefreshView setTitle:@"Aggiorna!" forState:SVPullToRefreshStateTriggered];
	[self.tableView.pullToRefreshView setTitle:@"Finito!" forState:SVPullToRefreshStateStopped];
	
	UIColor *foreGroundColor = [self.store userInterface][CLAAppDataStoreUIForegroundColorKey];
	
	[self.tableView.pullToRefreshView setTextColor:foreGroundColor];
	[self.tableView.pullToRefreshView setArrowColor:foreGroundColor];
}

-(void)callApi:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:CLAAppDataStoreDidStopSeachingPosition
												  object:self.store];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadContentsForStoreFetchedData:)
												 name:CLAAppDataStoreDidFetchNewData
											   object:self.store];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadContentsForStoreFetchedData:)
												 name:CLAAppDataStoreDidFailToFetchNewData
											   object:self.store];
	
	[self.store fetchRemoteDataWithTimeout:TIMEOUT skipCaching:NO];
}

@end
