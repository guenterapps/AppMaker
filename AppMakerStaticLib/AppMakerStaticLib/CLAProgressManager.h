//
//  CLAProgressManager.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 04/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CLAProgressManager : NSObject

@property (nonatomic) NSString *progressMessage;
@property (nonatomic) UILabel *progressLabel;

-(id)initWithMessage:(NSString *)message;

-(void)resetCounter;
-(void)countToDelta:(NSInteger )delta withInterval:(NSTimeInterval)interval;

@end
