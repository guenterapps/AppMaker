//
//  CLADataParserHelperProtocol.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 10/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLAModelProtocols.h"

@protocol CLADataParserHelperProtocol <NSObject>

-(id <CLATopic>)topicObjectForTopicCode:(NSString *)code;
-(id <CLAItem>)itemObjectForItemId:(NSString *)itemId topicCode:(NSString *)topicCode;
-(id <CLAImage>)imageObjectForImageCode:(NSString *)code forItem:(id <CLAItem>)item;
-(id <CLALocale>)localeObjectForLanguageKey:(NSString *)key;

@end
