//
//  CLALocalizedStringsStore.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 09/02/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  CLAPreferences;

@interface CLALocalizedStringsStore : NSObject

@property (nonatomic, readonly) CLAPreferences *preferences;

-(id)initWithPreferences:(CLAPreferences *)preferences;


-(NSString *)localizedStringForString:(NSString *)string;

@end
