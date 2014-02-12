//
//  CLALocalizedStringsStore.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 09/02/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLALocalizedStringsStore.h"
#import "CLAPreferences.h"

@interface CLALocalizedStringsStore ()

@property (nonatomic) CLAPreferences *preferences;

@end

@implementation CLALocalizedStringsStore


-(id)initWithPreferences:(CLAPreferences *)preferences
{
	NSParameterAssert(preferences);
	
	if (self = [super init])
	{
		self.preferences = preferences;
	}
	
	return self;
}

-(NSString *)localizedStringForString:(NSString *)string
{
	NSParameterAssert(string);

	NSString *preferredLanguage = [self.preferences valueForKey:CLAPreferredLanguageCodeKey];
	NSString *localizedString;
	
	NSLocale *locale	= [NSLocale localeWithLocaleIdentifier:preferredLanguage];
	NSString *country	= [locale objectForKey:NSLocaleLanguageCode];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"LocalizedStrings"
													 ofType:@"plist"
												inDirectory:nil
											forLocalization:country];
	
	if (!path)
	{
		localizedString = string;
	}
	else
	{
		NSDictionary *strings = [NSDictionary dictionaryWithContentsOfFile:path];
		
		localizedString = [strings objectForKey:string];
		
		NSAssert(localizedString, @"Could not find a localized string!");
	}
	
	return localizedString;
}

@end
