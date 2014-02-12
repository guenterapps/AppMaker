//
//  CLAMainTableViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#define TIMEOUT 10.0

#import "CLAMainTableViewController.h"
#import "CLAMapViewController.h"
#import "CLAMainTableViewCell.h"
#import "CLAMenuTableViewController.h"
#import "CLADetailViewController.h"
#import "CLAEventTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import "Item.h"

static NSString *const CLAMainTableViewCellIdentifier = @"CLAMainTableViewCell";
static NSString *const CLAEventTableViewCellIdentifier = @"CLAEventTableViewCell";

@interface CLAMainTableViewController ()
{
	CGFloat _scrolledHeight;
}

@property (nonatomic) NSString *lastTopicCode;

-(void)reloadContentsForNewTopic:(NSNotification *)notification;

-(void)reloadContentsForStoreFetchedData:(NSNotification *)notification;

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


-(void)setTopic:(id<CLATopic>)topic
{
	//NSParameterAssert(topic);

	_topic = topic;
	
	if (![[_topic topicCode] isEqualToString:self.lastTopicCode])
	{
		_scrolledHeight		= self.tableView.frame.size.height;
	}
	
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
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
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
	return self.items.count;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    id <CLAItem> item = [self.items objectAtIndex:indexPath.row];
	
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
		[eventCell setImage:[item mainImage]];

		
		eventCell.monthLabel.text = [[monthFormatter stringFromDate:item.date] uppercaseString];
		eventCell.dayLabel.text = [dayFormatter stringFromDate:item.date];
		
		cell = (UITableViewCell *)eventCell;
	}
	else
	{
		CLAMainTableViewCell *mainCell = (CLAMainTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CLAMainTableViewCellIdentifier forIndexPath:indexPath];
		
		[mainCell setTitle:item.title];
		
		[mainCell setImage:[item mainImage]];
		
		cell = (UITableViewCell *)mainCell;
	}

    return cell;

//	else
//	{
//		[self.store fetchMainImageForItem:item completionBlock:^(NSError *error)
//		{
//			if (error)
//			{
//				
//				NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento delle immagini! (Code: %i)", error.code];
//
//				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errore!"
//																	message:alertMessage
//																   delegate:nil
//														  cancelButtonTitle:@"Continua"
//														  otherButtonTitles:nil];
//				[alertView show];
//				
//				return;
//				
//			}
//
//			if ([item mainImage]) //check to avoid infinite requesting!
//			{
//				[(Item *)item generatePinMapFromMainImage];
//				
//				NSError *err;
//				[self.store save:&err];
//				
//				if (err)
//				{
//					UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Errore!"
//																 message:[NSString stringWithFormat:@"Errore nel salvataggio dei dati! (Code: %i)", [err code]]
//																delegate:nil
//													   cancelButtonTitle:@"Continua"
//													   otherButtonTitles:nil];
//					[av show];
//				}
//				
//				[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//			}
//		}];
//	}

}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self pushDetailViewControllerForItem:self.items[indexPath.row]];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	UILabel     *titleLabel			= [cell valueForKey:@"_titleLabel"];
	
	NSString *fontName		= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	CGFloat fontSize		= [[self.store userInterface][CLAAppDataStoreUIMainListFontSizeKey] floatValue];
	
	titleLabel.font			= [UIFont fontWithName:fontName size:fontSize];
	titleLabel.textColor	= [self.store userInterface][CLAAppDataStoreUIMainListFontColorKey];


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
#pragma mark Data handling

-(void)reloadContentsForStoreFetchedData:(NSNotification *)notification
{
	
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CLAAppDataStoreDidFailToFetchNewData object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CLAAppDataStoreDidFetchNewData object:nil];
	
	NSError *error = [notification userInfo][CLAAppDataStoreFetchErrorKey];
	
	if (error)
	{
		NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento dei dati! (Code: %i)", error.code];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errore!"
														message:alertMessage
													   delegate:nil
											  cancelButtonTitle:@"Continua"
											  otherButtonTitles:nil];
		[alert show];

	}
	
	[self.store asyncFetchMainImagesWithCompletionBlock:^(NSError *error)
	 {
		 if (error)
		 {
			 NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento delle immagini! (Code: %i)", error.code];
			 
			 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errore!"
																 message:alertMessage
																delegate:nil
													   cancelButtonTitle:@"Continua"
													   otherButtonTitles:nil];
			 [alertView show];
		 }
		 
		 [self.tableView.pullToRefreshView stopAnimating];
		 
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
												  selector:@selector(reloadContentsForStoreFetchedData:)
													  name:CLAAppDataStoreDidFetchNewData
													object:self.store];
		 
		 [[NSNotificationCenter defaultCenter] addObserver:self
												  selector:@selector(reloadContentsForStoreFetchedData:)
													  name:CLAAppDataStoreDidFailToFetchNewData
													object:self.store];

		 [self.store fetchRemoteDataWithTimeout:TIMEOUT];
	 }];
	
	[self.tableView.pullToRefreshView setTitle:@"Carico i dati..." forState:SVPullToRefreshStateLoading];
	[self.tableView.pullToRefreshView setTitle:@"Aggiorna!" forState:SVPullToRefreshStateTriggered];
	[self.tableView.pullToRefreshView setTitle:@"Finito!" forState:SVPullToRefreshStateStopped];
	
	//[self.tableView.pullToRefreshView setTextColor:[UIColor whiteColor]];
	//[self.tableView.pullToRefreshView setArrowColor:[UIColor whiteColor]];
}

@end
