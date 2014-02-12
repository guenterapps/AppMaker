//
//  CLADataParserTests.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 14/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CLAModelProtocols.h"
#import "CLADataParser.h"
#import "CLADataParserHelperProtocol.h"
#import "MockedImage.h"
#import "MockedItem.h"
#import "MockedTopic.h"
#import "OCMock.h"

static NSString *validTopicsData = @"["
"{"
"\"code\": \"chiese\","
"\"name\": \"Chiese\","
"\"updated_at\": \"2013-12-12T18:47:18+0000\""
"},"
"{"
"\"code\": \"monumenti\","
"\"name\": \"Monumenti\","
"\"updated_at\": \"2013-12-12T18:47:18+0000\""
"},"
"{"
"\"code\": \"party\","
"\"name\": \"Party\","
"\"updated_at\": \"2013-12-12T18:47:18+0000\""
"}"
"]";


static NSString *validContentsData = @""
"["
"{"
"\"distance\": 72.989913375114,"
"\"id\": 9,"
"\"name\": \"Circo Massimo\","
"\"description\": \"Il Circo Massimo...\","
"\"latitude\": \"41.88604\","
"\"longitude\": \"12.48554\","
"\"address\": \"Via del Circo Massimo, 1\","
"\"zipcode\": \"00184\","
"\"city\": \"Roma\","
"\"category\": {"
"\"code\": \"monumenti\","
"\"name\": \"Monumenti\","
"\"updated_at\": \"2013-12-12T18:47:18+0000\""
"},"
"\"is_event\": false,"
"\"updated_at\": \"2013-12-12T18:47:18+0000\","
"\"medias\": ["
"{"
"\"updated_at\": \"2013-12-12T18:47:18+0000\","
"\"type\": \"image\","
"\"filename\": \"52aa04b6785c6.jpeg\","
"\"url\": \"http://appandmap.danilosanchi.net/media/cache/medium/media/poi/images/52aa04b6785c6.jpeg\""
"},"
"{"
"\"updated_at\": \"2013-12-12T18:47:18+0000\","
"\"type\": \"video\","
"\"url\": \"http://www.youtube.com/watch?v=aksOAH7dYsQ\","
"\"thumb\": \"http://img.youtube.com/vi/aksOAH7dYsQ/hqdefault.jpg\""
"}"
"]"
"},"
"{"
"\"distance\": 73.689354554072,"
"\"id\": 8,"
"\"name\": \"Colosseo\","
"\"description\": \"Il Colosseo...\","
"\"latitude\": \"41.89023\","
"\"longitude\": \"12.49230\","
"\"address\": \"Piazza del Colosseo, 1\","
"\"zipcode\": \"00184\","
"\"city\": \"Roma\","
"\"category\": {"
"\"code\": \"monumenti2\","
"\"name\": \"Monumenti2\","
"\"updated_at\": \"2013-12-12T18:47:18+0000\""
"},"
"\"is_event\": false,"
"\"updated_at\": \"2013-12-12T18:47:18+0000\","
"\"medias\": ["
"{"
"\"updated_at\": \"2013-12-12T18:47:18+0000\","
"\"type\": \"image\","
"\"filename\": \"52aa04b6616b7.jpeg\","
"\"url\": \"http://appandmap.danilosanchi.net/media/cache/medium/media/poi/images/52aa04b6616b7.jpeg\""
"},"
"{"
"\"updated_at\": \"2013-12-12T18:47:18+0000\","
"\"type\": \"video\","
"\"url\": \"http://www.youtube.com/watch?v=gitm3wQauQg\","
"\"thumb\": \"http://img.youtube.com/vi/gitm3wQauQg/hqdefault.jpg\""
"}"
"]"
"}"
"]";

@interface CLADataParserTests : XCTestCase
{
	CLADataParser *parser;
	id delegate;
	NSData *invalidData;
	NSDateFormatter *dateFormatter;
	id topic;
	id item1;
	id item2;
	
	id media11;
	id media12;
	
	id media21;
	id media22;
}

@end

@implementation CLADataParserTests

- (void)setUp
{
    [super setUp];
   
	parser = [[CLADataParser alloc] init];
	
	delegate = [OCMockObject niceMockForProtocol:@protocol(CLADataParserHelperProtocol)];
	invalidData = [@"invalid" dataUsingEncoding:NSUTF8StringEncoding];
	
	parser.delegate = delegate;
	
	dateFormatter = [[NSDateFormatter alloc] init];
	
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss+SSSS"];
	
	topic = [[MockedTopic alloc] init];
	item1 = [[MockedItem alloc] init];
	item2 = [[MockedItem alloc] init];
	
	media11 = [[MockedImage alloc] init];
	media12 = [[MockedImage alloc] init];
	media21 = [[MockedImage alloc] init];
	media22 = [[MockedImage alloc] init];
	
	[media11 setItem:item1];
	[media12 setItem:item1];
	[media21 setItem:item2];
	[media22 setItem:item2];
	
	
	[[[delegate stub] andReturn:media11] imageObjectForItem:item1];
	[[[delegate stub] andReturn:media12] imageObjectForItem:item1];
	[[[delegate stub] andReturn:media21] imageObjectForItem:item2];
	[[[delegate stub] andReturn:media22] imageObjectForItem:item2];
	
	NSSet *set1 = [NSSet setWithObjects:media11,media12, nil];
	NSSet *set2 = [NSSet setWithObjects:media21, media22, nil];
	
	[item1 setImages:set1];
	[item2 setImages:set2];
	
}

- (void)tearDown
{
    parser = nil;
	delegate = nil;
	item1 = nil;
	topic = nil;
	item2 = nil;
	
	media12 = nil;
	media11 = nil;
	media21 = nil;
	media22 = nil;
    [super tearDown];
}

#pragma mark - parseTopics:error:

-(void)testParseTopicsReturnsErrorForInvalidData
{
	NSError *err;
	NSArray *topics = [parser parseTopics:invalidData error:&err];
	
	XCTAssertNil(topics);
	XCTAssertNotNil(err);
	XCTAssertNoThrow([parser parseTopics:invalidData error:nil]);
}

-(void)testParseTopicsDoesNotAskDelegateIfError
{
	[[delegate reject] itemObjectForTopicCode:OCMOCK_ANY];
	[parser parseTopics:invalidData error:nil];
	
	[delegate verify];
}

-(void)testParseTopicsAskDelegateAndPopulatesTopicObject
{

	[[[delegate stub] andReturn:topic] topicObject];
	
	NSArray *topics = [parser parseTopics:[validTopicsData dataUsingEncoding:NSUTF8StringEncoding] error:nil];
	
	XCTAssertTrue([topics count] == 3);
	
	id <CLATopic> lastTopic = [topics lastObject];
	
	XCTAssertEqualObjects(@"party", [lastTopic topicCode]);
	XCTAssertEqualObjects(@"Party", [lastTopic title]);
	XCTAssertNotNil([lastTopic lastUpdated]);
	
	NSString *dateString = [dateFormatter stringFromDate:[lastTopic lastUpdated]];
	
	XCTAssertEqualObjects(@"2013-12-12T18:47:18+0000", dateString);
	XCTAssertEqualObjects([(NSObject *)lastTopic valueForKey:@"ordering"], @(2));

}

#pragma mark - parseContents:error:
#pragma mark Items

-(void)testParseContentsReturnsErrorForInvalidData
{
	NSError *err;

	NSArray *topics = [parser parseContents:invalidData error:&err];
	
	XCTAssertNil(topics);
	XCTAssertNotNil(err);
	XCTAssertNoThrow([parser parseTopics:invalidData error:nil]);
}

-(void)testDataParserDoesNotAskDelegateIfError
{
	[[delegate reject] itemObjectForTopicCode:OCMOCK_ANY];
	[parser parseContents:invalidData error:nil];
	
	[delegate verify];
}

-(void)testParseItemsAskdDelegateAndCollectsItemsObjects
{
	[[[delegate expect] andReturn:item1] itemObjectForTopicCode:@"monumenti"];
	[[[delegate expect] andReturn:item2] itemObjectForTopicCode:@"monumenti2"];
	
	NSArray *contents = [parser parseContents:[validContentsData dataUsingEncoding:NSUTF8StringEncoding] error:nil];
	
	XCTAssertTrue([contents count] == 2);
	[delegate verify];
}

-(void)testParseItemsPopulateItemsProperties
{
	[[[delegate stub] andReturn:item1] itemObjectForTopicCode:@"monumenti"];
	[[[delegate stub] andReturn:item2] itemObjectForTopicCode:@"monumenti2"];
	
	NSArray *contents = [parser parseContents:[validContentsData dataUsingEncoding:NSUTF8StringEncoding] error:nil];
	
	id <CLAItem> first = contents[0];
	id <CLAItem> second = contents[1];
	
	XCTAssertEqualObjects([(NSObject *)first valueForKey:@"ordering"], @0);
	XCTAssertEqualObjects([(NSObject *)second valueForKey:@"ordering"], @1);
	
	XCTAssertEqualObjects([first title], @"Circo Massimo");
	XCTAssertEqualObjects([second address], @"Piazza del Colosseo, 1");
	
	XCTAssertFalse([[second isEvent] boolValue]);
	
	XCTAssertTrue([first coordinate].latitude == 41.88604);
	XCTAssertTrue([first coordinate].longitude == 12.48554);
	
}

#pragma mark Medias

-(void)testParseItemsAksDelegateForImagesObjects
{

	
	[[[delegate stub] andReturn:item1] itemObjectForTopicCode:OCMOCK_ANY];
	[[[delegate stub] andReturn:item2] itemObjectForTopicCode:OCMOCK_ANY];
	
	[parser parseContents:[validContentsData dataUsingEncoding:NSUTF8StringEncoding] error:nil];
	
	XCTAssertTrue([[item1 images] count] == 2);

	//NSSortDescriptor *ordering = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
	
	//NSArray *orderedMedia = [[[item1 images] allObjects] sortedArrayUsingDescriptors:@[ordering]];
	
	//XCTAssertEqualObjects([orderedMedia[0] valueForKey:@"fileName"], @"52aa04b6785c6.jpeg");
}


@end
