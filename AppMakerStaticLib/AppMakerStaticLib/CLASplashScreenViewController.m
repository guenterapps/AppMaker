//
//  CLASplashScreenViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#define JSONPROGRESS 50

#import "CLASplashScreenViewController.h"
#import "CLAAppDataStore.h"
#import "CLAProgressManager.h"
#import <QuartzCore/QuartzCore.h>

@interface CLASplashScreenViewController ()
{
	NSInteger _countStep;
	NSInteger _countTotal;
	CLAProgressManager *_progressManager;
}

-(void)setupCounter:(NSNotification *)notification;
-(void)updateCounter:(NSNotification *)notification;

@end


@implementation CLASplashScreenViewController

@synthesize activityIndicatorView = _activityIndicatorView;

-(NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
	UIColor *tintColor = [self.store userInterface][CLAAppDataStoreUISplashTintColorKey];

	self.view.backgroundColor = [UIColor blackColor];
	
	UIImageView *backImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
	backImage.image = [UIImage imageNamed:@"Default"];
	
	[self.view addSubview:backImage];
	self.view.layer.shadowColor = [UIColor blackColor].CGColor;
	self.view.layer.shadowOpacity = 0.5;
	
	_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
	[_activityIndicatorView setCenter:CGPointMake(screenSize.width / 2., (screenSize.height / 5.0) * 3.0)];
	
	[_activityIndicatorView setTintColor:tintColor];
	
	[self.view addSubview:_activityIndicatorView];
	
	[_activityIndicatorView startAnimating];
	
	UILabel *progress	= [[UILabel alloc] initWithFrame:CGRectMake(0., 0., 200., 50)];
	
	progress.font		= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:[[self.store userInterface][CLAAppDataStoreUIMenuFontSizeKey] floatValue]];
	
	progress.textColor = tintColor;
	progress.textAlignment	= NSTextAlignmentCenter;
	progress.center = CGPointMake(screenSize.width / 2., (screenSize.height / 10.0) * 9.0);
	
	[self.view addSubview:progress];
	
	_progressManager = [[CLAProgressManager alloc] initWithMessage:@"Aggiornamento"];
	_progressManager.progressLabel = progress;
	[_progressManager resetCounter];
	
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self selector:@selector(setupCounter:) name:CLAAppDataStoreWillFetchImages object:nil];

	[notificationCenter addObserver:self selector:@selector(updateCounter:) name:CLAAppDataStoreDidFetchImage object:nil];

	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}


-(void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)startUpdatingProgress
{
	[_progressManager countToDelta:JSONPROGRESS withInterval:0.5];
}

#pragma mark - private methods

-(void)setupCounter:(NSNotification *)notification
{
	NSNumber *total = [notification userInfo][CLATotalImagesToFetchKey];
	
	if ([total integerValue] > 0)
	{
		float_t imagesProgress = (float_t)(100 - JSONPROGRESS);
		
		NSAssert(imagesProgress > 0, @"Cannot have 0 progress for image fetching");
		
		float_t totalFloat		= (float_t)[total integerValue];
	
		_countStep				= (NSInteger)ceilf(imagesProgress/totalFloat);
		_countTotal				= MIN(100, JSONPROGRESS);
		
		[_progressManager countToDelta:_countTotal withInterval:0.1];
	}
	else
	{
		[_progressManager countToDelta:100 withInterval:0.2];
		
		double delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self.delegate splashScreenDidShowFullProgressPercentage];
		});
	}
}

-(void)updateCounter:(NSNotification *)notification
{
	static BOOL skip = NO;
	
	if (skip)
	{
		return;
	}

	_countTotal = MIN(100, _countTotal + _countStep);

	[_progressManager countToDelta:_countTotal withInterval:0.1];
	
	if (_countTotal == 100)
	{
		skip = YES;

		double delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self.delegate splashScreenDidShowFullProgressPercentage];
		});
	}
}

@end
