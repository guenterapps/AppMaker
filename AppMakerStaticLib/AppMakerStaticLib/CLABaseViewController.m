//
//  CLABaseViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLABaseViewController.h"
#import "CLADetailViewController.h"

@interface CLABaseViewController ()

-(void)popViewController;

@end

@implementation CLABaseViewController

-(id)init
{
	if (self = [super init])
	{
		if ([self iOS7Running])
		{
			self.edgesForExtendedLayout = UIRectEdgeNone;
		}
	}
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if ([self.view isKindOfClass:[UIScrollView class]])
	{
		UIEdgeInsets insets = UIEdgeInsetsMake(0., 0., 10., 0.);
		[(UIScrollView *)self.view setContentInset:insets];
	}
	
	NSAssert(self.store, @"ViewController does not appear to have a store!");
	NSAssert(self.appMaker, @"ViewController should belongs to the AppMaker");
}

-(void)toggleViewController
{
	NSException *e = [NSException exceptionWithName:@"AppMaker Exception"
											 reason:[NSString stringWithFormat:@"Ovveride %@!\n", NSStringFromSelector(_cmd)]
										   userInfo:nil];
	
	@throw e;
}

-(void)setupNavigationBarWithImage:(UIImage *)image
{
	NSParameterAssert(image);

	NSArray *rightBarButton = [self barButtonItemForSelector:@selector(toggleViewController) withImage:image];
	
	self.navigationItem.rightBarButtonItems = rightBarButton;
}

-(void)setupTableView:(UITableView *)tableView withCellIdentifier:(NSString *)identifier
{
	NSAssert([tableView isKindOfClass:[UITableView class]], @"Not a table view!\n");
	NSAssert([self conformsToProtocol:@protocol(UITableViewDelegate)], @"ViewController does not conform to UITableViewDelegate protocol!\n");
	NSAssert([self conformsToProtocol:@protocol(UITableViewDataSource)], @"ViewController does not conform to UITableViewDataSource protocol!\n");
	
	tableView.delegate			= (id <UITableViewDelegate>)self;
	tableView.dataSource		= (id <UITableViewDataSource>)self;
	tableView.separatorStyle	= UITableViewCellSeparatorStyleNone;
	
	if (identifier)
	{
		UINib *nib = [UINib nibWithNibName:identifier bundle:nil];
		
		NSAssert(nib, @"could not load cell %@", identifier);
		
		UITableView *cell = [nib instantiateWithOwner:nil options:nil][0];
		
		tableView.rowHeight = cell.bounds.size.height;
		
		[tableView registerNib:nib forCellReuseIdentifier:identifier];
	}
}

-(void)pushDetailViewControllerForItem:(id<CLAItem>)item
{
	NSAssert(self.navigationController, @"View Controller must push inside a navigation controller!\n");
	
	CLADetailViewController *detailViewController = [[CLADetailViewController alloc] initWithItem:item];
	
	detailViewController.store				= self.store;
	detailViewController.appMaker			= self.appMaker;
	detailViewController.localizedStrings	= self.appMaker.stringsStore;
	
	[self.navigationController pushViewController:detailViewController animated:YES];
}

-(void)setupBackButton
{
	UIImage *backImage = [self.store userInterface][CLAAppDataStoreUIBackIconKey];
		
	NSArray *backButton = [self barButtonItemForSelector:@selector(popViewController) withImage:backImage];
	
	self.navigationItem.leftBarButtonItems = backButton;
}


#pragma mark - private methods

-(NSArray *)barButtonItemForSelector:(SEL)selector withImage:(UIImage *)image
{
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	spacer.width = -10;
	
	NSArray *barButtonsArray;
	
	if ([self iOS7Running])
	{
		barButtonsArray = @[spacer, [[UIBarButtonItem alloc] initWithCustomView:button]];
	}
	else
	{
		barButtonsArray = @[[[UIBarButtonItem alloc] initWithCustomView:button]];
	}
	
	return barButtonsArray;
}

-(void)popViewController
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(void)setupTitleView
{
	UILabel *title		= [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 150, 41.0)];
	NSString *fontName	= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	CGFloat fontSize	= [[self.store userInterface][CLAAppDataStoreUIHeaderFontSizeKey] floatValue];
	
	title.textColor		= [self.store userInterface][CLAAppDataStoreUIHeaderFontColorKey];
	title.font			= [UIFont fontWithName:fontName size:fontSize];
	title.textAlignment = NSTextAlignmentCenter;
	
	self.navigationItem.titleView = title;
}

-(BOOL)iOS7Running
{
	return [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
}

@end
