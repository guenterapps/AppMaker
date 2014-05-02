//
//  AppMakerStaticLib.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 28/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#define TIMEOUT 10.0
#define REGISTERKEY @"devices/register"
#define PUSHANIMATIONKEY @"PUSHANIMATIONKEY"

#import <objc/runtime.h>

#import "AppMaker.h"
#import "CLAPanelViewController.h"
#import "CLAMainTableViewController.h"
#import "CLAMenuTableViewController.h"
#import "CLAMapViewController.h"
#import "CLACreditsViewController.h"
#import "CLADetailViewController.h"
#import "CLASplashScreenViewController.h"
#import "CLAPreferencesViewController.h"
#import "NSData+Hex.h"
#import "SVProgressHUD.h"
#import "CLAPreferences.h"
#import "CLALocalizedStringsStore.h"

#define ANGLE_TO_ANIMATE M_PI_4 / 4.0
#define X_TRANSLATION -30.0
#define Z_TRANSLATION -40.0
#define DURATION .4

static NSString *const CLAServerPushEnabledKey	= @"CLAServerPushEnabledKey";
static NSString *const CLALastAPNTokenKey		= @"CLALastAPNTokenKey";

@interface AppMaker ()
{
	UIViewController *_nextViewController;
	BOOL reloadData;
	BOOL _startFromNotification;
	NSString *_singleContentId;
	
	BOOL _loadApplicationIfNeeded;
	
	CLASplashScreenViewController *splashScreen;
}

@property (nonatomic) BOOL serverPushEnabled;
@property (nonatomic) NSDictionary *notifPayload;

@property (nonatomic) BOOL lockPresentApplication;

-(void)setupViewControllers;
-(id)setupViewControllerOfClass:(Class)class;
-(void)dismissSplashScreen;
-(void)setupAppearance;

- (void)handlePresentApplication;


//Notification callbacks
-(void)callApi:(NSNotification *)notification;
-(void)presentNextViewController:(NSNotification *)notification;
-(void)startSplashScreenProgressCounter:(NSNotification *)notification;
-(void)presentDetailControllerFromRemoteNotification:(NSNotification *)notification;
-(void)animateDetailController:(NSNotification *)notification;

-(void)getAPNToken;
-(NSString *)getStringFromToken:(NSData *)token;

@end

static NSDictionary *_notificationPayload;

@implementation AppMaker

#pragma mark - Creation Methods

@synthesize apiKey = _apiKey, rootViewController = _rootViewController, store = _store, cacheTimeout = _cacheTimeout;
@synthesize mapViewController = _mapViewController, menuTableViewController = _menuTableViewController, mainTableViewController = _mainTableViewController;

@synthesize lastAPNToken = _lastAPNToken, serverPushEnabled = _serverPushEnabled, notifPayload = _notifPayload;

static id appMaker = nil;

+(id)sharedMaker
{
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^
	{
		appMaker = [[self alloc] init];
	});
	
	return appMaker;
}

+(id)startWithApiKey:(NSString *)apiKey fromNotification:(NSDictionary *)payload
{
	_notificationPayload = payload;
	
	return [self startWithApiKey:apiKey];
}


+(id)startWithApiKey:(NSString *)apiKey
{
	
	NSAssert(!appMaker, @"Cannot start again!");

	AppMaker *maker = [self sharedMaker];
	
	//[maker.store preFetchData];

	[maker setApiKey:apiKey];
	
	[[NSNotificationCenter defaultCenter] addObserver:maker
											 selector:@selector(callApi:)
												 name:CLAAppDataStoreDidStopSeachingPosition
											   object:maker.store];
	
	[maker.store startUpdatingLocation];
	

	
	return maker;
}

-(id)init
{
	if (appMaker)
		return appMaker;
	
	if (self = [super init])
	{
		_store			= [[CLAAppDataStore alloc] init];
		_preferences	= [[CLAPreferences alloc] init];
		_stringsStore	= [[CLALocalizedStringsStore alloc] initWithPreferences:_preferences];
		
		_store.appMaker		= self;
		_store.preferences	= _preferences;
		
		if (_notificationPayload)
		{
			self.notifPayload = _notificationPayload;
		}
		
		[self setupAppearance];
		[self setupViewControllers];
	}
	
	return self;
}

-(void)consumeRemoteNotification:(NSDictionary *)notification
{
	[self setNotifPayload:notification];

	[SVProgressHUD showWithStatus:@"Carico i nuovi contenuti..." maskType:SVProgressHUDMaskTypeGradient];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	SEL callback = @selector(presentDetailControllerFromRemoteNotification:);
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:callback
												 name:CLAAppDataStoreDidFailToFetchNewData
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:callback
												 name:CLAAppDataStoreDidFetchNewData
											   object:nil];
	
	[self.store fetchRemoteDataForSingleContent:_singleContentId withTimeout:TIMEOUT];
	
	
}

#pragma mark - Setup Methods

-(void)setNotifPayload:(NSDictionary *)notifPayload
{
	NSParameterAssert(notifPayload);
	
	//id notificationId = notifPayload[@"id_notifica"];
	id notificationId = notifPayload[@"link"];
	
	//NSAssert(notificationId, @"Notification payload should containd 'id_notifica' key");
	
	if ([notificationId isKindOfClass:[NSNumber class]])
	{
		_singleContentId = [notificationId stringValue];
	}
	else
	{
		_singleContentId = notificationId;
	}

	_startFromNotification		= YES;
	
}

-(void)setApiKey:(NSString *)apiKey
{
	NSParameterAssert(apiKey);
	
	_apiKey = [apiKey copy];
	
}

-(void)setDefaultPosition:(CLLocation *)defaultPosition
{
	NSAssert(self.store, @"Should have a store now!");
	NSParameterAssert(defaultPosition);
	
	self.store.defaultPosition = defaultPosition;
	_defaultPosition = defaultPosition;
}

#pragma mark - helper methods

-(void)loadApplicationIfNeeded
{
	_loadApplicationIfNeeded = YES;
}

- (void)handlePresentApplication
{
	if (!self.lockPresentApplication)
	{
		self.lockPresentApplication = YES;
		[self presentApplication];
		[self getAPNToken];
	}
}

- (void)setupViewControllers
{

	CGRect screenSize = [UIScreen mainScreen].bounds;
	
	CLAPanelViewController *panel = [self setupViewControllerOfClass:[CLAPanelViewController class]];
	[panel setLeftFixedWidth:276.0];
	
	_mainTableViewController = [self setupViewControllerOfClass:[CLAMainTableViewController class]];
	_menuTableViewController = [self setupViewControllerOfClass:[CLAMenuTableViewController class]];
	_mapViewController		 = [self setupViewControllerOfClass:[CLAMapViewController class]];
	_creditsViewController	 = [self setupViewControllerOfClass:[CLACreditsViewController class]];
	
	_preferencesViewController = [self setupViewControllerOfClass:[CLAPreferencesViewController class]];
	
	_preferencesViewController.preferences = self.preferences;
	
	_menuTableViewController.delegate = (id <CLAMenuViewControllerDelegate>)_mapViewController;

	splashScreen = [self setupViewControllerOfClass:[CLASplashScreenViewController class]];

	splashScreen.delegate = self;
	
	_rootViewController = splashScreen;

	//setup main interface
	
	UINavigationController *mainNavigationController = [[UINavigationController alloc] initWithRootViewController:_mainTableViewController];
	
	UIColor *backgroundColor = [self.store userInterface][CLAAppDataStoreUIBackgroundColorKey];
	UIView *backgroundView	 = [[UIView alloc] initWithFrame:screenSize];
	backgroundView.backgroundColor = backgroundColor;
	[mainNavigationController.view insertSubview:backgroundView atIndex:0];
	
	
	UINavigationBar *navBar = [mainNavigationController navigationBar];
	
	UIColor *headerColor		= [self.store userInterface][CLAAppDataStoreUIHeaderColorKey];
	UIColor *headerTintColor	= [self.store userInterface][CLAAppDataStoreUIHeaderFontColorKey];
	
	[navBar setTintColor:headerTintColor];
	[navBar setBarTintColor:headerColor];
	[navBar setTranslucent:NO];
	
	//adding shadow to navigation bar
	
	CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
	UIColor * grayColor	= (UIColor *)[self.store userInterface][CLAAppDataStoreUIHeaderFontColorKey];
	grayColor = [grayColor colorWithAlphaComponent:0.8];
	gradient.colors			= @[(__bridge id)grayColor.CGColor, (__bridge id)[UIColor clearColor].CGColor];
	CGRect navBarFrame		= [mainNavigationController navigationBar].frame;
	navBarFrame.origin.y	= navBarFrame.size.height;
	navBarFrame.size.height *= 0.8;
	gradient.frame = navBarFrame;
	[navBar.layer addSublayer:gradient];
	
	if ([[self.store userInterface][CLAAppDataStoreUIShowSearchBar] boolValue])
		panel.leftPanel = [[UINavigationController alloc] initWithRootViewController:_menuTableViewController];
	else
		panel.leftPanel = _menuTableViewController;
	
	panel.centerPanel = mainNavigationController;
	
	_nextViewController = panel;

}

-(id)setupViewControllerOfClass:(Class)class
{
	id viewController = [[class alloc] init];
	
	[viewController setValue:self.store forKey:@"store"];
	[viewController setValue:self forKey:@"appMaker"];
	
	
	objc_property_t localizedStore = class_getProperty(class, "localizedStrings");
	
	if (localizedStore != NULL)
	{
		[viewController setValue:self.stringsStore forKey:@"localizedStrings"];
	}

	return viewController;
}

-(void)setupAppearance
{

}

-(void)setCacheTimeout:(NSTimeInterval)cacheTimeout
{
	_cacheTimeout = cacheTimeout;
	
	self.store.cacheTimeout = cacheTimeout;
}

#pragma mark - Callbacks

-(void)animateDetailController:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	id <CLAItem> item = [self.store contentWithIdentifier:_singleContentId];
	
	if (item)
	{
		id <CLATopic> topic = [item topic];
		
		CLAMainTableViewController *mainViewController = self.mainTableViewController;
		
		[mainViewController setTopic:topic];
		
		CLADetailViewController *detailViewController = [[CLADetailViewController alloc] initWithItem:item];
		detailViewController.appMaker = self;
		detailViewController.store = self.store;
		
		UINavigationController *navController = [[UINavigationController alloc] init];
		[navController setViewControllers:@[detailViewController]];
		
//		UIColor *backgroundColor = [self.store userInterface][CLAAppDataStoreUIBackgroundColorKey];
//		UIView *backgroundView	 = [[UIView alloc] initWithFrame:window.bounds];
//		backgroundView.backgroundColor = backgroundColor;
//		[navController.view insertSubview:backgroundView atIndex:0];
		
		CATransition *transition = [CATransition animation];
		
		transition.type	= kCATransitionPush;
		transition.subtype	= kCATransitionFromRight;
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		transition.duration = 0.35;
		transition.delegate = self;
		[transition setValue:navController forKey:@"NavControllerKey"];
		

		[self.rootViewController.view.layer addAnimation:transition forKey:PUSHANIMATIONKEY];
		
		[self.rootViewController.view addSubview:navController.view];

	}
}

-(void)presentDetailControllerFromRemoteNotification:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	NSError *error = [notification userInfo][CLAAppDataStoreFetchErrorKey];
	
	if (error)
	{
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errore!"
														message:@"Spiacenti, sembra che qualcosa sia andato storto con la connessione!"
													   delegate:nil
											  cancelButtonTitle:@"Annulla"
											  otherButtonTitles:nil];

	
		[SVProgressHUD dismiss];
		
		[alert show];
		
		return;

	}
	else
	{
		[self.store fetchMainImagesWithCompletionBlock:^(NSError *error)
		 {

			 if (error)
			 {
				 NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento delle immagini! (Code: %li)", (long)error.code];
				 
				 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errore!"
																	 message:alertMessage
																	delegate:nil
														   cancelButtonTitle:@"Continua"
														   otherButtonTitles:nil];
				 [SVProgressHUD dismiss];
				 
				 [alertView show];
			 }
			 else
			 {
				 
				 [[NSNotificationCenter defaultCenter] addObserver:self
														  selector:@selector(animateDetailController:)
															  name:SVProgressHUDDidDisappearNotification
															object:nil];
				 
				 [SVProgressHUD dismiss];

			 }
		 }];
	}
}

-(void)startSplashScreenProgressCounter:(NSNotification *)notification
{
	NSAssert([self.rootViewController isKindOfClass:[CLASplashScreenViewController class]], @"CLASplashScreen should be the root view controller");

	[(CLASplashScreenViewController *)self.rootViewController startUpdatingProgress];
}

- (void)presentApplication
{
	
	void (^resetAndInjectViewController)() = ^
	{
		id <CLATopic> topic;

		if ([[self.store topics] count] > 0)
			topic = [self.store topics][0];
		
		[self.mainTableViewController setTopic:topic];
		
		if ([[topic items] count] == 1)
		{
			id <CLAItem> item = [[topic items] anyObject];
			
			UINavigationController *navController			= (UINavigationController *)[(JASidePanelController *)_nextViewController centerPanel];
			
			NSAssert([navController isKindOfClass:[UINavigationController class]], @"should be a navigation controller");
			
			CLADetailViewController *detailViewController	= [[CLADetailViewController alloc] initWithItem:item];
			
			detailViewController.appMaker = self;
			detailViewController.localizedStrings = self.stringsStore;
			detailViewController.store = self.store;
			detailViewController.skipList = YES;
			
			[navController setViewControllers:@[detailViewController] animated:NO];
		}
	};
	
	if (_startFromNotification)
	{
		id <CLAItem> item = [self.store contentWithIdentifier:_singleContentId];
		
		if (item)
		{
			id <CLATopic> topic = [item topic];
			[self.mainTableViewController setTopic:topic];
	
			CLADetailViewController *detailViewController = [[CLADetailViewController alloc] initWithItem:item];
			detailViewController.appMaker = self;
			detailViewController.localizedStrings = self.stringsStore;
			detailViewController.store = self.store;

			[self.mainTableViewController.navigationController pushViewController:detailViewController animated:NO];

		}
		else
		{
#warning SHOW an ALERT FOR NEW CONTENT NOT FOUND!
			resetAndInjectViewController();
		}
	}
	else
	{
		resetAndInjectViewController();
	}


	[self dismissSplashScreen];
}

-(void)presentNextViewController:(NSNotification *)notification
{
#ifdef DEBUG
	NSLog(@"Presenting next view controller..");
#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	NSError *error = [notification userInfo][CLAAppDataStoreFetchErrorKey];
	
	if (error)
	{
		NSString *alertMessage;
		NSString *buttonMessage;
		
		reloadData = [[self.store topics] count] <= 1 ;
		
		if (!reloadData)
		{
			alertMessage = @"Sembra che tu non sia connesso: potrai comunque navigare l'App senza accedere agli strumenti online.";
			buttonMessage = @"Continua";
		}
		else
		{
			alertMessage	= @"Spiacenti, sembra che qualcosa sia andato storto con la connessione!";
			buttonMessage	= @"Riprova";
		}

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Modalità offline"
														message:alertMessage
													   delegate:self
											  cancelButtonTitle:buttonMessage
											  otherButtonTitles:nil];
		[alert show];
		
		return;
	}
	
	[splashScreen enableSkipLoadingButton];

	[self.store preFetchMainImagesWithCompletionBlock:^(NSError *preFetcherror)
	 {
		 
		 if (_loadApplicationIfNeeded)
		 {
			 _loadApplicationIfNeeded = NO;
			 
			 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				 [self handlePresentApplication];
			 });
			 
			 return;
		 }
		 
		 [self.store fetchMainImagesWithCompletionBlock:^(NSError *error)
		 {
			 NSError *presentingError = preFetcherror ? preFetcherror : error;
			 
			 [splashScreen disableSkipLoadingButton];
			 
			 if (presentingError)
			 {

				 NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento delle immagini! (Code: %li)", (long)presentingError.code];
				 
				 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errore!"
																	 message:alertMessage
																	delegate:self
														   cancelButtonTitle:@"Continua"
														   otherButtonTitles:nil];
				 [alertView show];
			 }
			 else if (_loadApplicationIfNeeded)
			 {
				 _loadApplicationIfNeeded = NO;
				 
				 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					 [self handlePresentApplication];
				 });
			 }
			 
		 }];
		 
		 
	 }];
	
}

-(void)callApi:(NSNotification *)notification
{
#ifdef DEBUG
	NSLog(@"Calling API..");
#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:CLAAppDataStoreDidStopSeachingPosition
												  object:self.store];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(presentNextViewController:)
												 name:CLAAppDataStoreDidFailToFetchNewData
											   object:self.store];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(presentNextViewController:)
												 name:CLAAppDataStoreDidFetchNewData
											   object:self.store];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(startSplashScreenProgressCounter:)
												 name:CLAAppDataStoreDidStartToFetchNewData
											   object:self.store];
	
	if (_startFromNotification)
	{
		[self.store fetchRemoteDataForSingleContent:_singleContentId withTimeout:TIMEOUT];
	}
	else
	{
		[self.store fetchRemoteDataWithTimeout:TIMEOUT skipCaching:NO];
	}

}

-(void)dismissSplashScreen
{
	[[(CLASplashScreenViewController *)_rootViewController activityIndicatorView] stopAnimating];
	
	[[[UIApplication sharedApplication].delegate window] setBackgroundColor:[self.store userInterface][CLAAppDataStoreUIBackgroundColorKey]];
	
	CALayer *splashScreenLayer = _rootViewController.view.layer;
	CALayer *fadingLayer = [CALayer layer];

	[splashScreenLayer addSublayer:fadingLayer];
	fadingLayer.opacity = 0.5;
	fadingLayer.frame = splashScreenLayer.bounds;
	fadingLayer.backgroundColor = [UIColor blackColor].CGColor;
	
	CATransform3D transform = CATransform3DIdentity;
	transform.m34 = - (1.0/500.0);
	//transform = CATransform3DRotate(transform, ANGLE_TO_ANIMATE, 0.0, 1.0, 0.0);
	transform = CATransform3DTranslate(transform, X_TRANSLATION, 0.0, Z_TRANSLATION);
	splashScreenLayer.transform = transform;
	splashScreenLayer.zPosition = -1;
	
	CABasicAnimation *dropAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	dropAnimation.fromValue	= [NSValue valueWithCATransform3D:CATransform3DIdentity];
	dropAnimation.toValue	= [NSValue valueWithCATransform3D:transform];
	dropAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	dropAnimation.duration = DURATION;
	
	CABasicAnimation *fadingAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadingAnimation.fromValue	= [NSNumber numberWithFloat:0.0];
	fadingAnimation.toValue		= [NSNumber numberWithFloat:.5];
	fadingAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
	
	CATransition *transition = [CATransition animation];
	transition.type		= kCATransitionPush;
	transition.subtype	= kCATransitionFromRight;
	transition.duration = DURATION;
	transition.delegate = self;
	
	[[UIApplication sharedApplication].keyWindow addSubview:_nextViewController.view];
	
	[_nextViewController.view.layer addAnimation:transition forKey:nil];
	[fadingLayer addAnimation:fadingAnimation forKey:nil];
	[splashScreenLayer addAnimation:dropAnimation forKey:nil];
	
	_rootViewController = _nextViewController;

	
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	if ([anim valueForKey:@"NavControllerKey"])
	{
		JASidePanelController *panelController = (JASidePanelController *)self.rootViewController;
		
		[panelController.view.layer removeAnimationForKey:PUSHANIMATIONKEY];

		UINavigationController *navController = (UINavigationController *)[anim valueForKey:@"NavControllerKey"];
	
		UIViewController *detailController = [navController viewControllers][0];

		[navController.view removeFromSuperview];

		if (panelController.state == JASidePanelLeftVisible)
		{
			[panelController showCenterPanelAnimated:NO];
		}
		
		UINavigationController *appNavController = (UINavigationController *)[panelController centerPanel];
		
		[appNavController setViewControllers:@[self.mainTableViewController, detailController]];

		
	}
	else
	{
		[[UIApplication sharedApplication].keyWindow setRootViewController:_nextViewController];
	}
}

#pragma mark -UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (reloadData)
	{
		reloadData = NO;
		[self callApi:nil];

	}
	else
	{
		double delayInSeconds = 1.0;

		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self handlePresentApplication];
		});
	}
	
	
}
#pragma mark - CLASplashScreenDelegateProtocol


-(void)splashScreenDidShowFullProgressPercentage
{
	[self handlePresentApplication];
}

#pragma mark - Push Notification Methods

-(BOOL)serverPushEnabled
{
	if (!_serverPushEnabled)
	{
		_serverPushEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:CLAServerPushEnabledKey];
	}

	return _serverPushEnabled;
}

-(void)setServerPushEnabled:(BOOL)serverPushEnabled
{
	_serverPushEnabled = serverPushEnabled;

	[[NSUserDefaults standardUserDefaults] setObject:@(serverPushEnabled) forKey:CLAServerPushEnabledKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSData *)lastAPNToken
{
	if (!_lastAPNToken)
	{
		_lastAPNToken = [[NSUserDefaults standardUserDefaults] objectForKey:CLALastAPNTokenKey];
	}

	return _lastAPNToken;
}

-(void)setLastAPNToken:(NSData *)lastAPNToken
{
	NSParameterAssert(lastAPNToken);
	
	_lastAPNToken = lastAPNToken;
	[[NSUserDefaults standardUserDefaults] setObject:lastAPNToken forKey:CLALastAPNTokenKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)getAPNToken
{

#ifdef DEBUG
	NSLog(@"Push notification authorization status: %i", [[UIApplication sharedApplication] enabledRemoteNotificationTypes]);
#endif

	BOOL currentStatusDenied = [[UIApplication sharedApplication] enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone;
	
	if (self.serverPushEnabled && currentStatusDenied)
	{
		[self registerAPNToken:self.lastAPNToken forNotificationsEnabled:NO];
	}
	else if (self.serverPushEnabled && !currentStatusDenied)
	{
		return;
	}
	else
	{
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert];
	}
}

-(NSString *)getStringFromToken:(NSData *)token
{
	
//	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
//	{
//		stringToken = [token base64EncodedStringWithOptions:0];
//	}
//	else
//	{
//		stringToken = [token base64Encoding];
//	}

	return [token hexRepresentationWithSpaces:NO capitals:NO];
}

-(void)registerAPNToken:(NSData *)token forNotificationsEnabled:(BOOL)enabled
{
	NSParameterAssert(token);
	
	self.lastAPNToken = token;
	
	void (^registerBlock)(void) = ^()
	{
		NSString *pathToRegister = [self.apiKey stringByAppendingPathComponent:REGISTERKEY];
	
		NSURL *notificationServerUrl = [NSURL URLWithString:pathToRegister];
		
		NSAssert(notificationServerUrl, @"Could not create notification server url!");
		
		UIDevice *device = [UIDevice currentDevice];
		
		NSString *device_id = [[device identifierForVendor] UUIDString];
		NSString *device_type = @"ios"; //[device systemName];
		NSString *version = [NSString stringWithFormat:@"%@-%@", [device model],[device systemVersion]];
		NSString *enable_notifications = [@(enabled) stringValue];
		
		NSDictionary *postDictionary = @{@"device_id": device_id,
										 @"device_type": device_type,
										 @"version": version,
										 @"enable_notifications": enable_notifications,
										 @"token": [self getStringFromToken:token]};
		
		NSError *jsonError;
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary
														   options:NSJSONWritingPrettyPrinted
															 error:&jsonError];
		
		NSAssert(@"Error creating json data for token registration: %@", [jsonError localizedDescription]);
		
#ifdef DEBUG
		NSLog(@"App&Map is registering APN token to server %@", [notificationServerUrl absoluteString]);
#endif
		
		NSError *error;
		NSHTTPURLResponse *httpResponse;
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:notificationServerUrl];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
		[request setHTTPBody:jsonData];
		
#ifdef DEBUG
		NSLog(@"App&Map is requesting to register APN token with request: %@\n%@\n%@", request, [request allHTTPHeaderFields], [request HTTPBody]);
#endif
		
		NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&httpResponse error:&error];

#ifdef DEBUG
		NSLog(@"App&Map did get reponse from notification server: %i - %@", httpResponse.statusCode, [NSString stringWithUTF8String:[response bytes]]);
#endif
		
		if (error)
		{
			NSLog(@"App&Map could not register APN token: %@", [error localizedDescription]);
		}
		else if (200 != httpResponse.statusCode)
		{
			NSLog(@"App&Map could not register APN token for server response: %li - %@", (long)httpResponse.statusCode, [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^()
			{
				[[AppMaker sharedMaker] setServerPushEnabled:enabled];
			});
		}
		
	};

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), registerBlock);
}

@end
