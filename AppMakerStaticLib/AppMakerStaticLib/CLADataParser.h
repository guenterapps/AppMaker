//
//  CLADataParser.h
//  AppMakerStaticLib
//
//  Created by Christian Lao on 10/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLADataParserHelperProtocol.h"

@interface CLADataParser : NSObject
{
	NSDictionary *topicMap;
	NSDictionary *itemMap;
	NSDictionary *mediaMap;
}

@property (weak, nonatomic) id <CLADataParserHelperProtocol> delegate;

-(NSArray *)parseTopics:(NSData *)topicsData error:(NSError *__autoreleasing*)error;
-(NSArray *)parseContents:(NSData *)contentsData error:(NSError *__autoreleasing*)error;
-(NSArray *)parseLocales:(NSData *)localesData error:(NSError *__autoreleasing*)error;


@end
