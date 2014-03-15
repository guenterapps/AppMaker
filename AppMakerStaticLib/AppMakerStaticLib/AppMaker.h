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


@class CLLocation, CLAMenuTableViewController, CLAMainTableViewController, CLAMapViewController, CLACreditsViewController, CLAPreferencesViewController, CLAPreferences, CLALocalizedStringsStore, SLComposeViewController;

@protocol CLASplashScreenDelegateProtocol;

/*
 *- create new project under a new folder (es: /newFolder/newProject)
 *- add appmaker as submodule in the same new folder (es: newFolder/AppMaker)
 *- update appmaker submodules
 *- add appmaker project as a subproject to the app project
 *- compile library to ensure everything is ok
 *- add user search path (es: ../AppMaker)
 *- from Custom App 'Compile Sources' add:
 *	- all cell's classes
 *	- all categories
 *	- CoreData model and classes
 *- add Mapkit, Social, MessageUI frameworks to the new project
 *- add static library in Custom App 'Link Binary with Libraries'
 *- import AppMaker.h header in Custom App project
 *- add custom fonts and assets in App project and info.plist (new fonts)
 *- add Cells in Custom App 'Copy Bundle Resources'
 *- set preprocessor globals
 *	- SERVERNAME @"http://admin.appandmap.com/api"
 *	- APIKEY @"20cd41ed35a365d45b24d1f387e4ccbcaf26360f"
 *- Start the app:
 *	[AppMaker startWithApiKey:@"#############"];
 *	self.window.rootViewController = [[AppMaker sharedMaker] rootViewController];
 */

typedef void (^ShareHandler)(SLComposeViewController *composer, id item);

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

@property (nonatomic, assign) BOOL useQRReader;
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

@property (nonatomic, copy) ShareHandler shareHandler;

/**
 *  Default value per-App for initial startup or
 *  in the case location services are disabled or denied.
 */

@property (nonatomic) CLLocation *defaultPosition;

@end
