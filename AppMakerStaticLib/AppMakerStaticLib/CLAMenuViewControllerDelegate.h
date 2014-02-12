//
//  CLAMenuViewControllerDelegate.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 31/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLAModelProtocols.h"

@protocol CLAMenuViewControllerDelegate <NSObject>

-(BOOL)menuViewControllerShouldSelectTopic:(id <CLATopic>)topic;

@end
