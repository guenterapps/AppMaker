//
//  CLAPreferences.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 04/02/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAPreferences.h"

#define DEFAULT_LANG @"en_EN"

NSString *const CLAPreferredLanguageCodeKey	= @"CLAPreferredLanguageCodeKey";
NSString *const CLADefaultLanguageCodeKey	= @"CLADefaultLanguageCodeKey";

@implementation CLAPreferences

+(void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{CLADefaultLanguageCodeKey: DEFAULT_LANG}];
}

-(id)valueForUndefinedKey:(NSString *)key
{
	id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	
	if ([CLAPreferredLanguageCodeKey isEqualToString:key])
	{
		if (!value)
		{
			value = [[NSLocale currentLocale] localeIdentifier];
		}
	}
	
	return value;
}

-(void)setValue:(id)value forKey:(NSString *)key
{
	NSParameterAssert(value);
	NSParameterAssert(key);
	
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

@end
