//
//  CLAMapViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 04/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLAMapViewController.h"
#import "CLAMainTableViewController.h"
#import "CLAModelProtocols.h"
#import "AppMaker.h"
#import "CLALocalizedStringsStore.h"

#define kLATITUDE_SPAN 1500.0
#define kLONGITUDE_SPAN 1500.0

static NSString *const CLAAnnotationViewReuseIdentifier = @"CLAAnnotationViewReuseIdentifier";

@interface CLAMapViewController ()
{
	BOOL _isDetailMap;
	NSString *_lastTopic;
	UIButton *navigateControl;

	id animator;
	id attachment;
}

-(void)reloadContentsForNewTopic:(NSNotification *)notification;
-(void)showDetailForSelectedItem:(id)sender;
-(void)openNavigationMap:(id)sender;
-(void)showAnnotationsForTopic:(id <CLATopic>)topic animated:(BOOL)animated;
-(MKCoordinateRegion)regionForPois:(NSArray *)pois;

@end


@implementation CLAMapViewController

@synthesize topic = _topic;

-(id)initDetailMap:(BOOL)isDetail
{
	if (self = [super init])
	{
		_isDetailMap = isDetail;
	}
	
	return self;
}

-(id)init
{
	return [self initDetailMap:NO];
}

-(void)toggleViewController
{
		
	CLAMainTableViewController *mainTableViewController = self.appMaker.mainTableViewController;
	mainTableViewController.topic = self.topic;
	mainTableViewController.skipAnimation = YES;
	
	[UIView transitionFromView:self.view toView:mainTableViewController.view
					  duration:0.30
					   options:UIViewAnimationOptionTransitionFlipFromLeft
					completion:^(BOOL finished)
	 {
		 
		 [self.navigationController setViewControllers:@[mainTableViewController]];
		 mainTableViewController.skipAnimation = NO;
		 
	 }];

}

-(void)setTopic:(id<CLATopic>)topic
{
	if (![self menuViewControllerShouldSelectTopic:topic])
		return;
	
	_topic		= topic;
	_lastTopic	= [[topic topicCode] copy];
	self.items	= [self.store poisForTopic:self.topic];
	
	[(UILabel *)self.navigationItem.titleView setText:[self.topic title]];

	[self showAnnotationsForTopic:self.topic animated:YES];
}

#pragma mark - View-related methods

-(MKMapView *)mapView
{
	return (MKMapView *)self.view;
}

-(void)loadView
{
	self.view = [[MKMapView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (!_isDetailMap)
	{
		self.items = [[self store] pois];
		[(UILabel *)self.navigationItem.titleView setText:[self.topic title]];
		[self showAnnotationsForTopic:self.topic animated:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reloadContentsForNewTopic:)
													 name:CLAMenuControllerDidSelectItemNotificationKey
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reloadContentsForNewTopic:)
													 name:CLAAppDataStoreDidInvalidateCache
												   object:nil];
	}
	else
	{
		[(UILabel *)self.navigationItem.titleView setText:[[self.items lastObject] title]];
		[self.mapView addAnnotations:self.items];
	}
	
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(reloadContentsForNewTopic:)
//												 name:CLAMenuControllerDidSelectItemNotificationKey
//											   object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self.mapView removeAnnotations:self.items];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	if (_isDetailMap)
	{
		
		CGSize screenSize = [[UIScreen mainScreen] bounds].size;
		
		CLLocationCoordinate2D coordinateToCenter = [(id <CLAItem>)self.items[0] coordinate];
		
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinateToCenter, kLATITUDE_SPAN, kLONGITUDE_SPAN);
		
		[self.mapView setRegion:region animated:NO];
		
		UIImage *buttonBackground = [UIImage imageNamed:@"get-directions"];

		
		navigateControl = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, buttonBackground.size.width, buttonBackground.size.height)];
		
		NSString *getDirections = [self.localizedStrings localizedStringForString:@"Get Directions"];
		
		[navigateControl setBackgroundImage:buttonBackground forState:UIControlStateNormal];
		[navigateControl setTitle:getDirections forState:UIControlStateNormal];
		[navigateControl setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

		[navigateControl addTarget:self action:@selector(openNavigationMap:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.view addSubview:navigateControl];

		navigateControl.center = CGPointMake(screenSize.width / 2.0, 6.4 * (screenSize.height / 8.0));
		
		[self setupBackButton];
		
		
	}
	else
	{
		UIImage *icon		= [self.store userInterface][CLAAppDataStoreUIListIconKey];
		[self setupNavigationBarWithImage:icon];
	}
	
	[self setupTitleView];

	[self.mapView setDelegate:self];

}

#pragma mark - private methods

- (MKCoordinateRegion)regionForPois:(NSArray *)pois
{
	
	MKCoordinateRegion region;
	MKCoordinateSpan span;
	CLLocationCoordinate2D coordinateToCenter;
	
	CLLocationCoordinate2D minimumCoordinate = CLLocationCoordinate2DMake(90, 180);
	CLLocationCoordinate2D maximumCoordinate = CLLocationCoordinate2DMake(-90, -180);
	
	maximumCoordinate.latitude	= [[pois valueForKeyPath:@"@max.latitude"] doubleValue];
	maximumCoordinate.longitude = [[pois valueForKeyPath:@"@max.longitude"] doubleValue];
	
	minimumCoordinate.latitude	= [[pois valueForKeyPath:@"@min.latitude"] doubleValue];
	minimumCoordinate.longitude = [[pois valueForKeyPath:@"@min.longitude"] doubleValue];
	
	coordinateToCenter.latitude		= (maximumCoordinate.latitude + minimumCoordinate.latitude) / 2.0;
	coordinateToCenter.longitude	= (maximumCoordinate.longitude + minimumCoordinate.longitude) / 2.0;
	
	span.latitudeDelta	= (maximumCoordinate.latitude - minimumCoordinate.latitude) * 1.5;
	span.longitudeDelta	= (maximumCoordinate.longitude - minimumCoordinate.longitude) * 1.5;
	
	region = MKCoordinateRegionMake(coordinateToCenter, span);

	return region;
}

//-(void)reloadContentsForNewTopic:(NSNotification *)notification
//{
//	id <CLATopic> topic = [[notification userInfo] objectForKey:CLAMenuControllerSelectedItemKey];
//	
//	NSParameterAssert(topic);
//	
//	self.topic = topic;
//	
//	self.items = [self.store contentsForTopic:self.topic];
//	
//#warning do stuff with new topic
//}

-(void)showAnnotationsForTopic:(id <CLATopic>)topic animated:(BOOL)animated
{
	
	CLLocationCoordinate2D coordinateToCenter;
	MKCoordinateRegion region;
	
	NSArray *pois = [self.store poisForTopic:self.topic];
	
	if ([pois count] > 1)
	{
		region = [self regionForPois:pois];
	}
	else
	{
		coordinateToCenter = [(id <CLAItem>)[pois lastObject] coordinate];
		
		region = MKCoordinateRegionMakeWithDistance(coordinateToCenter, kLATITUDE_SPAN, kLONGITUDE_SPAN);
	}

	[self.mapView removeAnnotations:[self.mapView annotations]];
	[self.mapView addAnnotations:pois];

	[self.mapView setRegion:region animated:animated];

}

-(void)openNavigationMap:(id)sender
{

	CLLocationCoordinate2D placemarkCoordinate = [(id <CLAItem>)self.items[0] coordinate];

	MKPlacemark *placeMark			= [[MKPlacemark alloc] initWithCoordinate:placemarkCoordinate addressDictionary:nil];
	MKMapItem *destinationLocation	= [[MKMapItem alloc] initWithPlacemark:placeMark];

	
	if ([self iOS7Running])
	{
		[self.mapView setShowsUserLocation:YES];
		
		animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.mapView];
		
		UIGravityBehavior *gravityBehaviour = [[UIGravityBehavior alloc] initWithItems:@[navigateControl]];

		gravityBehaviour.magnitude = 2.0;
		
		CGFloat xAttachment = CGRectGetMaxX(navigateControl.frame);
		CGFloat yAttachment	= CGRectGetMaxY(navigateControl.frame);
		CGFloat xOffset		= CGRectGetWidth(navigateControl.frame) / 2.0;
		CGFloat yOffset		= CGRectGetHeight(navigateControl.frame) / 2.0;
		
		attachment = [[UIAttachmentBehavior alloc] initWithItem:navigateControl offsetFromCenter:UIOffsetMake(xOffset, yOffset) attachedToAnchor:CGPointMake(xAttachment, yAttachment)];
		
		
		UICollisionBehavior *collisionBehaviour = [[UICollisionBehavior alloc] initWithItems:@[navigateControl]];
		
		[collisionBehaviour setCollisionDelegate:self];
		
		CGSize screen = [[UIScreen mainScreen] bounds].size;

#define SCREEN_OFFSET 40
		
		[collisionBehaviour addBoundaryWithIdentifier:@"CLAFloorBoundary" fromPoint:CGPointMake(0., screen.height + SCREEN_OFFSET) toPoint:CGPointMake(screen.width, screen.height + SCREEN_OFFSET)];
		
		[animator addBehavior:collisionBehaviour];
		[animator addBehavior:gravityBehaviour];
		[animator addBehavior:attachment];

	}
	else
	{
		NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking};

		[MKMapItem openMapsWithItems:@[destinationLocation] launchOptions:options];
	}

}

#pragma mark - MKMapViewDelegate

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	MKPolylineRenderer *poly = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
	
	[poly setLineWidth:4.0];
	[poly setStrokeColor:[self.store userInterface][CLAAppDataStoreUIHeaderFontColorKey]];
	
	return poly;
}

-(void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
	NSLog(@"%@:%@", NSStringFromSelector(_cmd), [error localizedDescription]);
	
	[self.mapView setShowsUserLocation:NO];
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{

	if (!userLocation)
	{
		return;
	}
	
	MKPlacemark *currentPlaceMark = [[MKPlacemark alloc] initWithCoordinate:userLocation.coordinate
														  addressDictionary:nil];
	
	MKMapItem *sourceLocation = [[MKMapItem alloc] initWithPlacemark:currentPlaceMark];
	
	CLLocationCoordinate2D placemarkCoordinate = [(id <CLAItem>)self.items[0] coordinate];
	
	MKPlacemark *placeMark			= [[MKPlacemark alloc] initWithCoordinate:placemarkCoordinate addressDictionary:nil];
	MKMapItem *destinationLocation	= [[MKMapItem alloc] initWithPlacemark:placeMark];
	
	
	MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
	[request setSource:sourceLocation];
	[request setDestination:destinationLocation];
	
	MKDirections *direction = [[MKDirections alloc] initWithRequest:request];
	
	[direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *err)
	 {
		 if (err)
		 {
			 [self.mapView setShowsUserLocation:NO];
			 NSLog(@"%@", [err localizedDescription]);

			 UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Errore!"
														  message:@"Non è stato trovato alcun percorso!"
														 delegate:nil
												cancelButtonTitle:@"Annulla"
												otherButtonTitles:nil];
			 [av show];
			 
			 return;
		 }
		 
		 MKRoute *route;
		 
		 if ((route = [[response routes] firstObject]))
		 {
			 MKCoordinateRegion region;
			 MKCoordinateSpan span;
			 CLLocationCoordinate2D coordinateToCenter;
			 
			 CLLocationCoordinate2D minimumCoordinate = CLLocationCoordinate2DMake(90, 180);
			 CLLocationCoordinate2D maximumCoordinate = CLLocationCoordinate2DMake(-90, -180);
			 
			 for (MKPlacemark *placemark in @[sourceLocation.placemark, destinationLocation.placemark])
			 {
				 if (placemark.coordinate.latitude > maximumCoordinate.latitude)
				 {
					 maximumCoordinate.latitude = placemark.coordinate.latitude;
				 }
				 
				 if (placemark.coordinate.longitude > maximumCoordinate.longitude)
				 {
					 maximumCoordinate.longitude = placemark.coordinate.longitude;
				 }
				 
				 if (placemark.coordinate.latitude < minimumCoordinate.latitude)
				 {
					 minimumCoordinate.latitude = placemark.coordinate.latitude;
				 }
				 
				 if (placemark.coordinate.longitude < minimumCoordinate.longitude)
				 {
					 minimumCoordinate.longitude = placemark.coordinate.longitude;
				 }
			 }
			 
			 coordinateToCenter.latitude		= (maximumCoordinate.latitude + minimumCoordinate.latitude) / 2.0;
			 coordinateToCenter.longitude	= (maximumCoordinate.longitude + minimumCoordinate.longitude) / 2.0;
			 
			 span.latitudeDelta	= (maximumCoordinate.latitude - minimumCoordinate.latitude) * 1.5;
			 span.longitudeDelta	= (maximumCoordinate.longitude - minimumCoordinate.longitude) * 1.5;
			 
			 region = MKCoordinateRegionMake(coordinateToCenter, span);
			 
			 [self.mapView setRegion:region animated:YES];
			 
			 [self.mapView addOverlay:[route polyline]];
		 }
		 else
		 {
			 NSString *errorMsg = @"Non è stato trovato alcun percorso!";
			 NSLog(@"%@", errorMsg);
			 
			 [self.mapView setShowsUserLocation:NO];

			 UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Errore!"
														  message:errorMsg
														 delegate:nil
												cancelButtonTitle:@"Annulla"
												otherButtonTitles:nil];
			 [av show];
		 }
		 
	 }];

}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
	
	MKAnnotationView *annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:CLAAnnotationViewReuseIdentifier];
	
	if (!annotationView)
		annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
													  reuseIdentifier:CLAAnnotationViewReuseIdentifier];
	
	if (![annotation conformsToProtocol:@protocol(CLAItem)])
	{
		return nil;
	}

	[annotationView setImage:[(id <CLAItem>)annotation pinMap]];
	
	annotationView.enabled = YES;
	annotationView.canShowCallout = YES;

	if (!_isDetailMap)
	{
		UIButton *callOut = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[callOut addTarget:self action:@selector(showDetailForSelectedItem:) forControlEvents:UIControlEventTouchUpInside];
		
		annotationView.rightCalloutAccessoryView = callOut;
	}

	return annotationView;
}

-(void)showDetailForSelectedItem:(id)sender
{
	id <CLAItem> selectedItem = [[self.mapView selectedAnnotations] lastObject];

	[self pushDetailViewControllerForItem:selectedItem];
}

#pragma mark CLAMenuControllerSelectedItemKey Notification

-(void)reloadContentsForNewTopic:(NSNotification *)notification
{
	if (!self.navigationController)
	{
		return;
	}

	id <CLATopic> topic = [[notification userInfo] objectForKey:CLAMenuControllerSelectedItemKey];
	
	if (!topic)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"topicCode", _lastTopic];
		topic = [[[self.store topics] filteredArrayUsingPredicate:predicate] lastObject];
	}
	
	self.topic = topic;
}

#pragma mark - CLAMenuTableViewControllerDelegate

-(BOOL)menuViewControllerShouldSelectTopic:(id<CLATopic>)topic
{
	if (!self.navigationController)
	{
		return YES;
	}
	
	NSArray *pois = [self.store poisForTopic:topic];
	
	if ([pois count] == 0)
	{
		NSString *alertMessage = [NSString stringWithFormat:@"Non sono presenti POI per la categoria %@", [topic title]];
		UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Attenzione!"
													 message:alertMessage
													delegate:nil
										   cancelButtonTitle:@"Continua"
										   otherButtonTitles:nil];
		
		[av show];
		
		return NO;
	}

	return YES;
}

#pragma mark - UICollisionBehaviourDelegate
-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
	[(UIDynamicAnimator *)animator removeBehavior:attachment];
}


@end
