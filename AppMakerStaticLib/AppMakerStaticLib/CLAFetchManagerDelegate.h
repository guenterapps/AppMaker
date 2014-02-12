//
//  CLAFetchManagerDelegate.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 10/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLAFetchManager;

@protocol CLAFetchManagerDelegate <NSObject>

-(void)fetchMananager:(CLAFetchManager *)fetchMananager didFailWithError:(NSError *)error;
-(void)fetchManagerDidFinishFetchingData:(CLAFetchManager *)fetchMananager;
-(void)fetchManagerdidStartFetchingData:(CLAFetchManager *)fetchMananager;

@end
