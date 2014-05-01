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
#define ITINERARI	@"position"

#define WALKING_DISTANCE 3000

static NSString *const CLAAnnotationViewReuseIdentifier = @"CLAAnnotationViewReuseIdentifier";

static NSString *const CLADirectionsTransportTypeKey = @"CLADirectionsTransportTypeKey";
static NSString *const CLALaunchOptionsDirectionsModeKey = @"CLALaunchOptionsDirectionsModeKey";

@interface CLAMapViewController ()
{
	BOOL _isDetailMap;
	NSString *_lastTopic;
	UIButton *navigateControl;
	
	BOOL _isItinerary;

	id animator;
	id attachment;
}

-(void)reloadContentsForNewTopic:(NSNotification *)notification;
-(void)showDetailForSelectedItem:(id)sender;
-(void)openNavigationMap:(id)sender;
-(void)showAnnotationsForTopic:(id <CLATopic>)topic animated:(BOOL)animated;
-(MKCoordinateRegion)regionForPois:(NSArray *)pois;
- (void)calculateDirectionsFromSourceLocation:(MKMapItem *)sourceLocation
						toDestinationLocation:(MKMapItem *)destinationLocation
									setRegion:(BOOL)set;
-(void)showDirectionsForItinerary:(id <CLATopic>)topic;
-(UIImage *)pinMapForItem:(id <CLAItem>)item;
-(void)showDirectionToPoi;

-(NSDictionary *)suggestedTransportTypeFromItem:(MKMapItem *)from toItem:(MKMapItem *)to;

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
	
	[self.mapView removeAnnotations:[self.mapView annotations]];
	[self.mapView removeOverlays:[self.mapView overlays]];
	
	if (NSOrderedSame == [ITINERARI compare:[self.topic sortOrder] options:NSCaseInsensitiveSearch])
	{
		_isItinerary = YES;
		[self showDirectionsForItinerary:self.topic];
	}
	else
	{
		_isItinerary = NO;
		[self.mapView removeOverlays:self.mapView.overlays];
	}
	
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
		[self showDirectionToPoi];
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
		
		UIImage *buttonBackground = [[UIImage imageNamed:@"get-directions"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		
		navigateControl = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, buttonBackground.size.width, buttonBackground.size.height)];
		
		navigateControl.tintColor = [self.store userInterface][CLAAppDataStoreUIDirectionsColorKey];
		
		NSString *getDirections = [self.localizedStrings localizedStringForString:@"Get Directions"];
		
		[navigateControl setBackgroundImage:buttonBackground forState:UIControlStateNormal];
		[navigateControl setTitle:getDirections forState:UIControlStateNormal];
		[navigateControl setTitleColor:[self.store userInterface][CLAAppDataStoreUIDirectionsTextColorKey]
							  forState:UIControlStateNormal];

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

-(NSDictionary *)suggestedTransportTypeFromItem:(MKMapItem *)from toItem:(MKMapItem *)to
{
	CLLocation *fromLocation	= from.placemark.location;
	CLLocation *toLocation		= to.placemark.location;
	
	CLLocationDistance distance = [fromLocation distanceFromLocation:toLocation];
	
	NSString *launchOptionMode;
	NSUInteger directionTransportType;
	
	if (ABS(distance > WALKING_DISTANCE))
	{
		launchOptionMode		= MKLaunchOptionsDirectionsModeDriving;
		directionTransportType	= MKDirectionsTransportTypeAutomobile;
	}
	else
	{
		launchOptionMode		= MKLaunchOptionsDirectionsModeWalking;
		directionTransportType	= MKDirectionsTransportTypeWalking;
	}
	
	return @{CLALaunchOptionsDirectionsModeKey	: launchOptionMode,
			 CLADirectionsTransportTypeKey		: @(directionTransportType)};
}

-(UIImage *)pinMapForItem:(id<CLAItem>)item
{
	UIImage *pinMap = [item pinMap];
	UIImage *start	= [UIImage imageNamed:@"start"];
	UIImage *end	= [UIImage imageNamed:@"end"];
	
	if (_isItinerary)
	{
		UIImage *(^pinMapDrawer)(UIImage *) = ^(UIImage *flag)
		{
			CGFloat scale = [[UIScreen mainScreen] scale];
			
			CGSize pinSize	= CGSizeMake(pinMap.size.width, pinMap.size.height);
			CGSize flagSize	= CGSizeMake(flag.size.width, flag.size.height);
			
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(pinSize.width + flagSize.width * 0.5, pinSize.height), NO, scale);
			
			[pinMap drawInRect:CGRectMake(0., 0., pinSize.width, pinSize.height)];
			[flag drawInRect:CGRectMake(pinSize.width * 0.425, 10., flagSize.width, flagSize.height)];
			
			UIImage *compositeImage = UIGraphicsGetImageFromCurrentImageContext();
			
			UIGraphicsEndImageContext();
			
			return compositeImage;
		};
		
		if (0 == [[item ordering] integerValue])
		{
			pinMap = pinMapDrawer(start);
		}
		else if ((NSInteger)([[self.store poisForTopic:self.topic] count] - 1) == [[item ordering] integerValue])
		{
			pinMap = pinMapDrawer(end);
		}
	}
	
	return pinMap;
}

-(void)showDirectionToPoi
{
	[self.mapView setShowsUserLocation:YES];
}

-(void)showDirectionsForItinerary:(id <CLATopic>)topic
{
	NSArray *items = [self.store poisForTopic:topic];
	
	for (NSInteger i = 1; i < [items count]; ++i)
	{
		id <CLAItem> source			= (id <CLAItem>)items[i - 1];
		id <CLAItem> destination	= (id <CLAItem>)items[i];
		
		MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:[source coordinate]
															 addressDictionary:nil];
		MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:[destination coordinate] addressDictionary:nil];
		
		
		[self calculateDirectionsFromSourceLocation:[[MKMapItem alloc] initWithPlacemark:sourcePlacemark]
							  toDestinationLocation:[[MKMapItem alloc] initWithPlacemark:destinationPlacemark]
																			   setRegion:NO];
		

	}
}

- (void)calculateDirectionsFromSourceLocation:(MKMapItem *)sourceLocation toDestinationLocation:(MKMapItem *)destinationLocation setRegion:(BOOL)set
{
	MKDirectionsRequest *request	= [[MKDirectionsRequest alloc] init];
	NSDictionary *suggestedOptions	= [self suggestedTransportTypeFromItem:sourceLocation toItem:destinationLocation];
	
	[request setSource:sourceLocation];
	[request setDestination:destinationLocation];
	[request setTransportType:[suggestedOptions[CLADirectionsTransportTypeKey] integerValue]];
	
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
			 if (set)
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
				 span.longitudeDelta	= (maximumCoordinate.longitude - minimumCoordinate.longitude) * 1.8;
				 
				 region = MKCoordinateRegionMake(coordinateToCenter, span);
				 
				 [self.mapView setRegion:region animated:YES];
			 }

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
	
	[self.mapView addAnnotations:pois];

	[self.mapView setRegion:region animated:animated];

}

-(void)openNavigationMap:(id)sender
{

	CLLocationCoordinate2D placemarkCoordinate = [(id <CLAItem>)self.items[0] coordinate];

	MKPlacemark *placeMark			= [[MKPlacemark alloc] initWithCoordinate:placemarkCoordinate addressDictionary:nil];
	MKMapItem *destinationLocation	= [[MKMapItem alloc] initWithPlacemark:placeMark];

	MKPlacemark *fromPlacemark		= [[MKPlacemark alloc] initWithCoordinate:self.mapView.userLocation.coordinate
															addressDictionary:nil];
	
	MKMapItem *sourceLocation		= [[MKMapItem alloc] initWithPlacemark:fromPlacemark];

	
//	if ([self iOS7Running])
//	{
//		[self.mapView setShowsUserLocation:YES];
//		
//		animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.mapView];
//		
//		UIGravityBehavior *gravityBehaviour = [[UIGravityBehavior alloc] initWithItems:@[navigateControl]];
//
//		gravityBehaviour.magnitude = 2.0;
//		
//		CGFloat xAttachment = CGRectGetMaxX(navigateControl.frame);
//		CGFloat yAttachment	= CGRectGetMaxY(navigateControl.frame);
//		CGFloat xOffset		= CGRectGetWidth(navigateControl.frame) / 2.0;
//		CGFloat yOffset		= CGRectGetHeight(navigateControl.frame) / 2.0;
//		
//		attachment = [[UIAttachmentBehavior alloc] initWithItem:navigateControl offsetFromCenter:UIOffsetMake(xOffset, yOffset) attachedToAnchor:CGPointMake(xAttachment, yAttachment)];
//		
//		
//		UICollisionBehavior *collisionBehaviour = [[UICollisionBehavior alloc] initWithItems:@[navigateControl]];
//		
//		[collisionBehaviour setCollisionDelegate:self];
//		
//		CGSize screen = [[UIScreen mainScreen] bounds].size;
//
//#define SCREEN_OFFSET 40
//		
//		[collisionBehaviour addBoundaryWithIdentifier:@"CLAFloorBoundary" fromPoint:CGPointMake(0., screen.height + SCREEN_OFFSET) toPoint:CGPointMake(screen.width, screen.height + SCREEN_OFFSET)];
//		
//		[animator addBehavior:collisionBehaviour];
//		[animator addBehavior:gravityBehaviour];
//		[animator addBehavior:attachment];
//
//	}

	NSDictionary *suggestedOptions = [self suggestedTransportTypeFromItem:sourceLocation
																   toItem:destinationLocation];
	
	NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey: suggestedOptions[CLALaunchOptionsDirectionsModeKey]};

	[MKMapItem openMapsWithItems:@[destinationLocation] launchOptions:options];


}

#pragma mark - MKMapViewDelegate

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
	MKPolylineRenderer *poly = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
	UIColor *polyColor = [self.store userInterface][CLAAppDataStoreUIDirectionsPolylineColorKey];
	
	if (!polyColor)
		polyColor = [UIColor blueColor];
	
	[poly setLineWidth:4.0];
	[poly setStrokeColor:polyColor];
	[poly setAlpha:0.6];
	
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
	
	
	[self calculateDirectionsFromSourceLocation:sourceLocation
						  toDestinationLocation:destinationLocation
									  setRegion:YES];

}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
	
	MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:CLAAnnotationViewReuseIdentifier];
	//[self.mapView dequeueReusableAnnotationViewWithIdentifier:CLAAnnotationViewReuseIdentifier];
	
	if (!annotationView)
		annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
													  reuseIdentifier:CLAAnnotationViewReuseIdentifier];
	
	if (![annotation conformsToProtocol:@protocol(CLAItem)])
	{
		return nil;
	}
	
	//[annotationView setImage:[self pinMapForItem:(id <CLAItem>)annotation]];
	
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
