//
//  AppMakerStaticLib.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 28/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CLAAppDataStore.h"


@class CLLocation, CLAMenuTableViewController, CLAMainTableViewController, CLAMapViewController, CLACreditsViewController, CLAPreferencesViewController, CLAPreferences, CLALocalizedStringsStore;

@protocol CLASplashScreenDelegateProtocol;

/**
 *  How to setup the Library on Custom App:
 *
 *  - import Headers in Custom App project
 *	- add static library in Custom App 'Link Binary with Libraries'
 *  - add core data model in in Custom App 'Compile Sources' 
 *  - add Cells in Custom App 'Copy Bundle Resources'
 *  - add Categories and Cell classes to compile in Custom App Project
 */

//Menu selection notification globals
extern NSString *const CLAMenuControllerDidSelectItemNotificationKey;
extern NSString *const CLAMenuControllerSelectedItemKey;
extern NSString *const CLAMenuControllerSelectedIndexPathKey;

@interface AppMaker : NSObject <UIAlertViewDelegate, CLASplashScreenDelegateProtocol>

#pragma mark - Startup Methods

+(id)startWithApiKey:(NSString *)apiKey;
+(id)startWithApiKey:(NSString *)apiKey fromNotification:(NSDictionary *)payload;
+(id)sharedMaker;

#pragma mark - Remote Notification handling

-(void)registerAPNToken:(NSData *)token forNotificationsEnabled:(BOOL)enabled;
-(void)consumeRemoteNotification:(NSDictionary *)notification;

#pragma mark - View Controllers;

@property (nonatomic, readonly) CLAMainTableViewController *mainTableViewController;
@property (nonatomic, readonly) CLAMenuTableViewController	*menuTableViewController;
@property (nonatomic, readonly) CLAMapViewController *mapViewController;
@property (nonatomic, readonly) CLACreditsViewController *creditsViewController;
@property (nonatomic, readonly) CLAPreferencesViewController *preferencesViewController;

#pragma mark - Properties

@property (nonatomic, readonly) CLAPreferences *preferences;
@property (nonatomic, readonly) CLALocalizedStringsStore *stringsStore;

@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, readonly) CLAAppDataStore *store;
@property (nonatomic, readonly) UIViewController *rootViewController;

@property (nonatomic) BOOL shouldSetupMenuController;
@property (nonatomic) NSTimeInterval cacheTimeout;

#pragma mark Push Notifications Properties

@property (nonatomic, readonly) BOOL serverPushEnabled;
@property (nonatomic) NSData *lastAPNToken;

/**
 *  Default value per-App for initial startup or
 *  in the case location services are disabled or denied.
 */

@property (nonatomic) CLLocation *defaultPosition;

@end
