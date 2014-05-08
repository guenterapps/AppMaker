//
//  CLAMapViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 04/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "CLABaseViewController.h"
#import "CLAModelProtocols.h"
#import "CLAMenuViewControllerDelegate.h"

@class CLALocalizedStringsStore;

@interface CLAMapViewController : CLABaseViewController <MKMapViewDelegate, CLAMenuViewControllerDelegate, UICollisionBehaviorDelegate>

@property (nonatomic) NSArray *items;
@property (nonatomic) id <CLATopic>topic;

-(id)initDetailMap:(BOOL)isDetail;
-(MKMapView *)mapView;

@end
