//
//  CLASplashScreenViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 02/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

@protocol CLASplashScreenDelegateProtocol <NSObject>

-(void)splashScreenDidShowFullProgressPercentage;

@end

#import <UIKit/UIKit.h>
#import "CLABaseViewController.h"

@interface CLASplashScreenViewController : CLABaseViewController

@property (nonatomic, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak) id <CLASplashScreenDelegateProtocol> delegate;


-(void)finishCounterWithInterval:(NSTimeInterval)interval;

-(void)startUpdatingProgress;
-(void)enableSkipLoadingButton;
-(void)disableSkipLoadingButton;
-(void)skipImageLoading;

@end
