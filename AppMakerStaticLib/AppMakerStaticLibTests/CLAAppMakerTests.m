//
//  CLAAppMakerTests.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 01/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppMaker.h"
#import "CLAAppDataStore.h"
#import "OCMock.h"
#import "XCTestCase+Utils.h"
#import <objc/runtime.h>
#import <CoreLocation/CoreLocation.h>

@interface AppMaker (Fake)

+(id)nonSingletonSharedMaker;

@end

@implementation AppMaker (Fake)

+(id)nonSingletonSharedMaker
{
	return [[self alloc] init];
}

@end

@interface CLAAppMakerTests : XCTestCase
{
	AppMaker *app;
	CLLocation *defaultLocation;
	
	id locationManager;
}

@end

@interface CLAAppDataStore (Fake)

-(void)fake_startUpdatingLocation;

@end

@implementation CLAAppDataStore (Fake)

-(void)fake_startUpdatingLocation
{
	objc_setAssociatedObject(self, @"updateLocationCalled", @YES, OBJC_ASSOCIATION_RETAIN);
}

@end

@implementation CLAAppMakerTests

- (void)setUp
{
    [super setUp];
	
	[self exchangeImplementationForClass:[CLAAppDataStore class] sel1:@selector(startUpdatingLocation) sel2:@selector(fake_startUpdatingLocation)];
	
    [self exchangeClassImplementationForClass:[AppMaker class] sel1:@selector(sharedMaker) sel2:@selector(nonSingletonSharedMaker)];

	defaultLocation = [[CLLocation alloc] initWithLatitude:0.0000 longitude:0.0000];
	locationManager = [OCMockObject niceMockForClass:[CLLocationManager class]];

	app = [AppMaker startWithApiKey:@"apiKey"];
	
	[app.store setValue:locationManager forKey:@"locationManager"];
}

- (void)tearDown
{
	app = nil;
	
	[self exchangeClassImplementationForClass:[AppMaker class] sel1:@selector(sharedMaker) sel2:@selector(nonSingletonSharedMaker)];
	[self exchangeImplementationForClass:[CLAAppDataStore class] sel1:@selector(startUpdatingLocation) sel2:@selector(fake_startUpdatingLocation)];
	
	defaultLocation = nil;
	locationManager = nil;
	
    [super tearDown];
}

#pragma mark - Setup

-(void)testAppMakerSetsApiKey
{
	XCTAssertEqualObjects(app.apiKey, @"apiKey");
}

-(void)testAppMakerSetupStore
{
	XCTAssertNotNil(app.store);
}

-(void)testAppMakerSetsDefaultPositionOnStore
{
	app.defaultPosition = defaultLocation;
	XCTAssertEqualObjects(app.store.defaultPosition, defaultLocation);
}

-(void)testAppMakerStartsPositionFixOnStore
{
	
	NSNumber *called =objc_getAssociatedObject(app.store, @"updateLocationCalled");
	
	XCTAssertTrue([called boolValue]);


}

@end
