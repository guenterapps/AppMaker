//
//  CLAFetchManagerTests.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 10/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CLAFetchManager.h"
#import "CLADataParser.h"
#import "CLADataParserHelperProtocol.h"
#import <CoreData/CoreData.h>
#import "OCMock.h"
#import "CLAFetchManagerDelegate.h"
#import "CLAModelProtocols.h"
#import <CoreLocation/CoreLocation.h>
#import "MockedItem.h"
#import "MockedTopic.h"
#import "MockedImage.h"

typedef BOOL (^ResponseHandler)(NSData *response);

@interface CLAFetchManagerTests : XCTestCase
{
	NSPersistentStoreCoordinator *coord;
	CLAFetchManager *topicManager;
	CLAFetchManager *fullManager;
	CLAFetchManager *standalone;
	id connection;
	id delegate;
	id dataParser;
	id context;
	CLLocationCoordinate2D position;
	NSString *topic;
	NSString *endpoint;
	NSError *error;
	
	NSOperationQueue *notificationQueue;
}

@end


@implementation CLAFetchManagerTests

- (void)setUp
{
    [super setUp];
	
	topic		= @"topic";
	endpoint	= @"endpoint";
    
	//topicManager	= [[CLAFetchManager alloc] initForTopic:topic withEndpoint:endpoint];
	fullManager	= [[CLAFetchManager alloc] initWithEndpoint:endpoint];
	
	standalone = [[CLAFetchManager alloc] init];
	
	connection	= [OCMockObject niceMockForClass:[NSURLConnection class]];
	
	position = CLLocationCoordinate2DMake(40.321232313, 50.1212121212);

	delegate = [OCMockObject niceMockForProtocol:@protocol(CLAFetchManagerDelegate)];
	
	topicManager.delegate = delegate;
	fullManager.delegate = delegate;
	
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
	coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[coord addPersistentStoreWithType:NSInMemoryStoreType configuration:nil
								  URL:nil
							  options:nil
								error:nil];
	
	fullManager.coordinator = coord;
	topicManager.coordinator = coord;
	standalone.coordinator = coord;

	error = [NSError errorWithDomain:@"domani" code:100 userInfo:nil];
	
	dataParser  = [OCMockObject niceMockForClass:[CLADataParser class]];
	context		= [OCMockObject niceMockForClass:[NSManagedObjectContext class]];

	
	notificationQueue = [[NSOperationQueue alloc] init];
	[fullManager setValue:notificationQueue forKey:@"_notificationQueue"];

}

- (void)tearDown
{
	[connection stopMocking];

	connection = nil;

	topicManager = nil;
	fullManager = nil;
	delegate= nil;
	error = nil;
	dataParser = nil;
	standalone = nil;
	notificationQueue = nil;
    [super tearDown];
}

#pragma mark Utils
- (NSData *)setupGoodTopics
{
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
	NSData *topicsData = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
	
	[[[connection stub] andReturn:topicsData] sendSynchronousRequest:OCMOCK_ANY
												   returningResponse:[OCMArg setTo:response]
															   error:[OCMArg setTo:nil]];
	return topicsData;
}

#pragma mark - Warm Up Tests

- (void)testManagerConformsToParserHelperDelegate
{
	XCTAssertTrue([fullManager conformsToProtocol:@protocol(CLADataParserHelperProtocol)]);
}

-(void)testMainSetupDataParser
{
	[fullManager main];
	
	XCTAssertNotNil(fullManager.dataParser);
	XCTAssertEqualObjects(fullManager.dataParser.delegate, fullManager);
}

-(void)testMainSetupPrivateContext
{
	[fullManager main];
	
	XCTAssertNotNil(fullManager.context);
	XCTAssertTrue(fullManager.context.concurrencyType == NSPrivateQueueConcurrencyType);
	XCTAssertEqualObjects(coord, fullManager.context.persistentStoreCoordinator);
	
}
-(void)testInitSetsEndpointAndTopic
{
	XCTAssertEqualObjects([fullManager valueForKey:@"_endpoint"], endpoint);

}

#pragma mark - URL handling

#pragma mark Categories fetch

-(void)testFullManagerPassTopicUrlToConnection
{
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];
	
	NSURL *url = [NSURL URLWithString:@"endpoint/categories"];
	
	[[connection expect] sendSynchronousRequest:[OCMArg checkWithBlock:^BOOL(id obj)
	{
		NSURLRequest *request = (NSURLRequest *)obj;
		return [request.URL isEqual:url] && request.timeoutInterval == 30.0;
												 
	}]
						  returningResponse:[OCMArg setTo:response]
									  error:[OCMArg setTo:nil]];

	
	[fullManager main];
	
	[connection verify];

}


-(void)testFullManagerInformsDelegateForConnectionError
{
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];
	[[connection stub] sendSynchronousRequest:OCMOCK_ANY
						  returningResponse:[OCMArg setTo:response]
									  error:[OCMArg setTo:error]];
	
	[[delegate expect] fetchMananager:fullManager didFailWithError:error];
	
	[fullManager main];
	
	[notificationQueue waitUntilAllOperationsAreFinished];
	
	[delegate verify];
	
}

-(void)testFullManagerInformsDelegateIfResponseDifferentFrom200Or304
{
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];

	NSData *data = [@"response" dataUsingEncoding:NSUTF8StringEncoding];
	
	[[[connection stub] andReturn:data] sendSynchronousRequest:OCMOCK_ANY
											  returningResponse:[OCMArg setTo:response]
														  error:[OCMArg setTo:nil]];
	
	[[delegate expect] fetchMananager:fullManager didFailWithError:OCMOCK_ANY];
	[fullManager main];
	[notificationQueue waitUntilAllOperationsAreFinished];
	[delegate verify];
	
}

//-(void)testFullManagerSavesDataIfNoError
//{
//	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:404 HTTPVersion:nil headerFields:nil];
//	NSData *data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
//
//	[[[connection stub] andReturn:data ] sendSynchronousRequest:OCMOCK_ANY
//											  returningResponse:[OCMArg setTo:response]
//														  error:[OCMArg setTo:nil]];
//	[fullManager main];
//	
//	XCTAssertEqualObjects(data, [fullManager valueForKey:@"_topicsData"]);
//	
//}

-(void)testFullManagerAsksParserToParseTopics
{
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:nil];
	NSData *topicsData = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
	
	[[[connection stub] andReturn:topicsData] sendSynchronousRequest:OCMOCK_ANY
											  returningResponse:[OCMArg setTo:response]
														  error:[OCMArg setTo:nil]];

	fullManager.dataParser = dataParser;
	
	[[[dataParser expect] andReturn:[NSArray array] ] parseTopics:topicsData error:[OCMArg setTo:nil]];
	
	[fullManager main];
	
	[dataParser verify];
}

-(void)testFullManagerIfParserReturnsNilInformsDelegateWithError
{
	NSData *topicsData;
	topicsData = [self setupGoodTopics];
	
	fullManager.dataParser = dataParser;
	
	[[[dataParser stub] andReturn:nil] parseTopics:topicsData error:[OCMArg setTo:error]];
	
	[[delegate expect] fetchMananager:fullManager didFailWithError:error];
	
	[fullManager main];
		
	[notificationQueue waitUntilAllOperationsAreFinished];
	
	[delegate verify];

}

#pragma mark Contents fetch

//-(void)testFullManagerCallsContentsApi
//{
//	NSData *topicsData;
//	topicsData = [self setupGoodTopics];
//	
//	fullManager.dataParser = dataParser;
//	fullManager.position = position;
//	
//	id topic1 = [OCMockObject niceMockForProtocol:@protocol(CLATopic)];
//	id topic2 = [OCMockObject niceMockForProtocol:@protocol(CLATopic)];
//	
//	[[[topic1 stub] andReturn:@"monumenti"] topicCode];
//	[[[topic2 stub] andReturn:@"ristoranti"] topicCode];
//	
//	[fullManager main];
//	
//
//	
//}

#pragma mark - importContentsJSON:error:

-(void)testImportSetupContextAndParser
{
	NSError *err;
	NSData *data = [@"asd" dataUsingEncoding:NSUTF8StringEncoding];
	
	[standalone importContentsJSON:data error:&err];
	
	XCTAssertNotNil(standalone.dataParser);
	XCTAssertEqualObjects(standalone.dataParser.delegate, standalone);
	
	XCTAssertNotNil(standalone.context);
	XCTAssertTrue(standalone.context.concurrencyType == NSPrivateQueueConcurrencyType);
	XCTAssertEqualObjects(coord, standalone.context.persistentStoreCoordinator);
	
	
}

-(void)testImportSetupAsksParser
{
	NSError *err;
	NSData *data = [@"asd" dataUsingEncoding:NSUTF8StringEncoding];
	
	standalone.dataParser = dataParser;
	
	[[dataParser expect] parseContents:data error:[OCMArg setTo:nil]];
	
	[standalone importContentsJSON:data error:&err];
	
	[dataParser verify];
	
}

-(void)testImportReturnsObjects
{
	NSError *err;
	NSData *data = [@"asd" dataUsingEncoding:NSUTF8StringEncoding];
	
	standalone.dataParser = dataParser;
	
	[[[dataParser stub] andReturn:@[@1]] parseContents:data error:[OCMArg setTo:nil]];
	
	NSArray *objects = [standalone importContentsJSON:data error:&err];
	
	XCTAssertTrue([objects count] == 1);
}

-(void)testImportSetsError
{
	NSError *err;
	NSData *data = [@"asd" dataUsingEncoding:NSUTF8StringEncoding];
	
	standalone.dataParser = dataParser;
	
	[[[dataParser stub] andReturn:nil] parseContents:data error:[OCMArg setTo:error]];
	
	[standalone importContentsJSON:data error:&err];
	
	XCTAssertEqualObjects(error, err);
}


#pragma mark - importTopicsJSON:error:

-(void)testImportTopicCallsDataParser
{
	NSError *err;
	NSData *data = [@"asd" dataUsingEncoding:NSUTF8StringEncoding];
	
	standalone.dataParser = dataParser;
	
	[[[dataParser expect] andReturn:@[@1]] parseTopics:data error:[OCMArg setTo:OCMOCK_ANY]];
	
	[standalone importTopicsJSON:data error:&err];
	
	[dataParser verify];
}

#pragma mark - CLADataParserHelperProtocol

-(void)testOnTopicObjectAsksContextForTopic
{
	id entity = [OCMockObject niceMockForClass:[NSEntityDescription class]];
	
	[[[entity expect] andReturn:[NSNull null] ] insertNewObjectForEntityForName:@"Topic" inManagedObjectContext:fullManager.context];
	
	id obj = [fullManager topicObject];
	
	[entity verify];
	
	XCTAssertEqualObjects((id <CLATopic>)[NSNull null], obj);
}


-(void)testOnTopicObjectCollectsCreatedTopics
{
	id entity = [OCMockObject niceMockForClass:[NSEntityDescription class]];
	
	[[[entity stub] andReturn:@0] insertNewObjectForEntityForName:@"Topic" inManagedObjectContext:fullManager.context];

	NSMutableSet *objects = [fullManager valueForKey:@"_collectedTopics"];
	
	XCTAssertTrue([objects containsObject:@0]);

}

-(void)testOnItemForTopicAsksContextForItem
{
	MockedItem *item		= [[MockedItem alloc] init];
	MockedTopic *mockedTopic = [[MockedTopic alloc] init];
	
	[fullManager setValue:[NSSet setWithObject:mockedTopic] forKey:@"_collectedTopics"];
	
	mockedTopic.topicCode = @"code";
	
	id entity = [OCMockObject niceMockForClass:[NSEntityDescription class]];
	
	[[[entity expect] andReturn:item] insertNewObjectForEntityForName:@"Item" inManagedObjectContext:fullManager.context];
	
	id obj = [fullManager itemObjectForTopicCode:@"code"];
	
	[entity verify];
	
	XCTAssertEqualObjects(item, obj);
}

-(void)testOnItemForTopicSetsRelashionship
{
	MockedItem *item		= [[MockedItem alloc] init];
	MockedTopic *mockedTopic = [[MockedTopic alloc] init];
	
	mockedTopic.topicCode = @"code";
	
	[fullManager setValue:[NSSet setWithObject:mockedTopic] forKey:@"_collectedTopics"];
	
	id entity = [OCMockObject niceMockForClass:[NSEntityDescription class]];
	
	[[[entity expect] andReturn:item] insertNewObjectForEntityForName:@"Item" inManagedObjectContext:fullManager.context];
	
	id <CLAItem> obj = [fullManager itemObjectForTopicCode:@"code"];
	
	XCTAssertEqualObjects([obj topic], mockedTopic);
}

-(void)testOnImageForItemAskContextAndSetImage
{
	MockedItem *item		= [[MockedItem alloc] init];
	MockedImage *image		= [[MockedImage alloc] init];
	
	id entity = [OCMockObject niceMockForClass:[NSEntityDescription class]];
	
	[[[entity expect] andReturn:image] insertNewObjectForEntityForName:@"Image" inManagedObjectContext:fullManager.context];
	
	id <CLAImage> obj = [fullManager imageObjectForItem:item];
	
	[entity verify];
	
	XCTAssertEqualObjects(image, obj);
	XCTAssertEqualObjects(item, [obj item]);
	
}

@end
