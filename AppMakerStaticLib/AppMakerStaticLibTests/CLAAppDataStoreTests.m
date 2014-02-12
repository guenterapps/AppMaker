//
//  CLAAppDataStoreTests.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 30/11/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CLAAppDataStore.h"
#import "OCMock.h"
#import "XCTestCase+Utils.h"
#import <CoreLocation/CoreLocation.h>

@interface CLAAppDataStoreTests : XCTestCase
{
	CLAAppDataStore *store;
	
	id userDefaults;
	id locationManager;
	
	CLLocation *defaultPosition;
	CLLocation *lastPosition;
	
}

@end

@implementation CLAAppDataStoreTests

- (void)setUp
{
    [super setUp];
	
	store = [[CLAAppDataStore alloc] init];
	
	userDefaults	= [OCMockObject niceMockForClass:[NSUserDefaults class]];
	locationManager	= [OCMockObject niceMockForClass:[CLLocationManager class]];
	
	defaultPosition = [[CLLocation alloc] initWithLatitude:30.0 longitude:30.0];
	lastPosition	= [[CLLocation alloc] initWithLatitude:10.0 longitude:10.0];
	
	store.defaultPosition = defaultPosition;
	
	[store setValue:userDefaults forKey:@"userDefaults"];
	[store setValue:locationManager forKey:@"locationManager"];

}

- (void)tearDown
{
    store			= nil;
	userDefaults	= nil;
	defaultPosition = nil;
	locationManager = nil;
    [super tearDown];
}

-(void)testStoreSetsStandardUserDefaults
{
	[store setValue:nil forKey:@"userDefaults"];
	NSUserDefaults *standardUserDefaults= [store valueForKey:@"userDefaults"];
	
	XCTAssertEqualObjects([NSUserDefaults standardUserDefaults], standardUserDefaults);
}

#pragma mark - CLLocationManager setup

-(void)testStoreSetsLocationManager
{
	[store setValue:nil forKey:@"locationManager"];
	CLLocationManager *manager = [store valueForKey:@"locationManager"];
	
	XCTAssertNotNil(manager);
	XCTAssertTrue([manager isMemberOfClass:[CLLocationManager class]]);
}

-(void)testStoreReturnsDefaultPositionIfLastPositionNil
{
	XCTAssertEqualObjects(defaultPosition, store.lastPosition);
}

-(void)testStoreReturnsLastPosition
{
	[[[userDefaults stub] andReturn:@10.0] objectForKey:CLALastPositionLatitudeKey];
	[[[userDefaults stub] andReturn:@10.0] objectForKey:CLALastPositionLongitudeKey];
	
	XCTAssertEqual((double)lastPosition.coordinate.latitude, (double)store.lastPosition.coordinate.latitude);
	XCTAssertEqual((double)lastPosition.coordinate.longitude, (double)store.lastPosition.coordinate.longitude);
}

#pragma mark startUpdatingLocation

-(void)testStartUpdatingLocationAsksForAvailability
{
	[[[locationManager expect] classMethod] locationServicesEnabled];
	
	[store startUpdatingLocation];
	
	[locationManager verify];
	
	[locationManager stopMocking];
}

-(void)testStartUpdatingLocationIfNotAvailableDoesNotAskManager
{
	[[[[locationManager stub] classMethod] andReturnValue:@NO] locationServicesEnabled];
	
	[[locationManager reject] startUpdatingLocation];
	
	[store startUpdatingLocation];
	
	[locationManager verify];
	
	[locationManager stopMocking];
}

-(void)testStartUpdatingLocationAsksLocationManager
{
	[[[[locationManager stub] classMethod] andReturnValue:@YES] locationServicesEnabled];
	
	[[locationManager expect] startUpdatingLocation];
	
	[store startUpdatingLocation];
	
	[locationManager verify];
	
	[locationManager stopMocking];
}

-(void)testStartUpdatingLocationSetsDelegate
{
	[[[[locationManager stub] classMethod] andReturnValue:@YES] locationServicesEnabled];

	
	[[locationManager expect] setDelegate:store];
	
	[store startUpdatingLocation];
	
	[locationManager verify];
}

-(void)testStartUpdatingLocationSetupLocationManagerProperties
{
	[[[[locationManager stub] classMethod] andReturnValue:@YES] locationServicesEnabled];

	[store setValue:nil forKey:@"locationManager"];
	
	[store startUpdatingLocation];
	
	CLLocationManager *manager = [store valueForKey:@"locationManager"];
	
	XCTAssertTrue(manager.desiredAccuracy == kCLLocationAccuracyHundredMeters);
	XCTAssertTrue(manager.distanceFilter == 500.0);
	
	[locationManager stopMocking];
}

#pragma mark CLLocationManger delegate methods

#pragma mark locationManager:didFailWithError:

-(void)testlocationManagerdidFailWithErrorStopsIfErrorIsDenied
{
	NSError *err = [NSError errorWithDomain:@"domain" code:kCLErrorDenied userInfo:nil];
	
	[[locationManager expect] stopUpdatingLocation];
	
	[store locationManager:nil didFailWithError:err];
	
	[locationManager verify];
}

-(void)testlocationManagerdidFailWithErrorDoesNotStops
{
	NSError *err = [NSError errorWithDomain:@"domain" code:0 userInfo:nil];
	
	[[locationManager reject] stopUpdatingLocation];
	
	[store locationManager:nil didFailWithError:err];
	
	[locationManager verify];
}

#pragma mark locationManager:didUpdateLocations:

-(void)testlocationManagerdidUpdateLocationsSetsLastPositionIfNewerThan30Seconds
{
	CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:10.0 longitude:10.0];
	
	[[userDefaults expect] setObject:@10.0 forKey:CLALastPositionLatitudeKey];
	
	[store locationManager:nil didUpdateLocations:@[newLocation]];
	
	[locationManager verify];
	
	[[userDefaults expect] setObject:@10.0 forKey:CLALastPositionLongitudeKey];
	
	[store locationManager:nil didUpdateLocations:@[newLocation]];
	
	[locationManager verify];
}

-(void)testlocationManagerdidUpdateLocationsTellsLocationManagerToStop
{
	CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:10.0 longitude:10.0];
	
	[[locationManager expect] stopUpdatingLocation];
	
	[store locationManager:nil didUpdateLocations:@[newLocation]];
	
	[locationManager verify];
}

#pragma mark locationManagerdidChangeAuthorizationStatus

-(void)testLocationManagerdidChangeAuthorizationStatusIfAuthorizedTellsLocationManagerToStart
{
	[[locationManager expect] startUpdatingLocation];
	
	[store locationManager:nil didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorized];
	
	[locationManager verify];
}

-(void)testLocationManagerdidChangeAuthorizationStatusDoesNotTellLocationManagerToStart
{
	[[locationManager reject] startUpdatingLocation];
	
	[store locationManager:nil didChangeAuthorizationStatus:0];
	
	[locationManager verify];
}


@end
