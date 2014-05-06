//
//  CLASplashScreenViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#define JSONPROGRESS 20

#import <QuartzCore/QuartzCore.h>

#import "CLASplashScreenViewController.h"
#import "CLAAppDataStore.h"
#import "CLAProgressManager.h"
#import "CLALocalizedStringsStore.h"


@interface CLASplashScreenViewController ()
{
	NSInteger _countStep;
	NSInteger _countTotal;
	NSInteger _countTarget;
	CLAProgressManager *_progressManager;
	UIButton *stopLoading;
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
	
	CGSize screenSize	= [[UIScreen mainScreen] bounds].size;
	UIColor *tintColor	= [self.store userInterface][CLAAppDataStoreUISplashTintColorKey];
	UIFont *font		= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:[[self.store userInterface][CLAAppDataStoreUIMenuFontSizeKey] floatValue]];

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
	
	progress.font		= font;
	
	progress.textColor = tintColor;
	progress.textAlignment	= NSTextAlignmentCenter;
	//progress.center = CGPointMake(screenSize.width / 2., (screenSize.height / 10.0) * 9.0);
	
	[self.view addSubview:progress];
	
	NSString *stopLoadingText = [self.localizedStrings localizedStringForString:@"Stop loading"];
	
	_progressManager = [[CLAProgressManager alloc] initWithMessage:[self.localizedStrings localizedStringForString:@"Updating"]];
	_progressManager.progressLabel = progress;
	[_progressManager resetCounter];
	
	stopLoading = [UIButton buttonWithType:UIButtonTypeSystem];
	[stopLoading setTintColor:tintColor];
	[stopLoading.titleLabel setFont:font];
	[stopLoading setTitle:stopLoadingText forState:UIControlStateNormal];
	[stopLoading addTarget:self action:@selector(skipImageLoading) forControlEvents:UIControlEventTouchUpInside];
	
	stopLoading.enabled = NO;
	stopLoading.hidden = YES;
	
	[self.view addSubview:stopLoading];
	
	for (UIView *view in self.view.subviews)
	{
		view.translatesAutoresizingMaskIntoConstraints = NO;
	}
	
	NSArray  *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[progress]-[stopLoading]-|"
																	options:NSLayoutFormatAlignAllCenterX
																	metrics:nil
																	  views:NSDictionaryOfVariableBindings(progress, stopLoading)];
	NSLayoutConstraint *center = [NSLayoutConstraint constraintWithItem:self.view
															  attribute:NSLayoutAttributeCenterX
															  relatedBy:NSLayoutRelationEqual
																 toItem:progress
															  attribute:NSLayoutAttributeCenterX
															 multiplier:1.0
															   constant:0.];
	
	[self.view addConstraints:constraints];
	[self.view addConstraint:center];
	
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
	[_progressManager countToDelta:JSONPROGRESS withInterval:2.0];
}

-(void)enableSkipLoadingButton
{
	[UIView animateWithDuration:0.4 animations:^()
	{
		stopLoading.enabled = YES;
		stopLoading.hidden = NO;
		_progressManager.progressLabel.alpha = 0.5;
		
	}];
}

-(void)disableSkipLoadingButton
{
	[UIView animateWithDuration:0.2 animations:^()
	 {
		 stopLoading.enabled = NO;
	 }];
}

#pragma mark - private methods

-(void)setupCounter:(NSNotification *)notification
{
	NSNumber *total = [notification userInfo][CLATotalImagesToFetchKey];
	
	if ([total integerValue] > 0)
	{
		_countTarget = [total integerValue];
		_countStep	 = JSONPROGRESS;
		_countTotal	 = 0;
		
		[_progressManager countToDelta:MIN(100, JSONPROGRESS) withInterval:0.2];
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

	_countTotal++;
	
	NSInteger delta		= (NSInteger)((100 - JSONPROGRESS) * _countTotal/(float_t)_countTarget) + JSONPROGRESS;
	
	BOOL targetReached	= _countTotal == _countTarget;

	if (ABS(delta - _countStep) > 0)
	{
		if (targetReached)
			delta = 100;
		
		_countStep = delta;

		[_progressManager countToDelta:delta withInterval:0.1];
	}

	if (targetReached)
	{
		skip = YES;

		double delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self.delegate splashScreenDidShowFullProgressPercentage];
		});
	}
}

-(void)skipImageLoading
{
	stopLoading.enabled = NO;

	[self.store skipImageLoading];
	[self.appMaker loadApplicationIfNeeded];
	
//	double delayInSeconds = 0.2;
//	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//		[self.delegate splashScreenDidShowFullProgressPercentage];
//	});
}

@end
