//
//  CLAPanelViewController.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "JASidePanelController.h"
#import "CLAAppDataStore.h"
#import "AppMaker.h"

@interface CLAPanelViewController : JASidePanelController

@property (nonatomic) CLAAppDataStore *store;
@property (nonatomic, weak) AppMaker *appMaker;

@end
