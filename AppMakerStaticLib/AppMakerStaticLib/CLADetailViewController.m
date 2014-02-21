//
//  CLADetailViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 07/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLADetailViewController.h"
#import "CLAHeaderDetailCell.h"
#import "CLAActionsDetailCell.h"
#import "CLAAddressDetailCell.h"
#import "CLAModelProtocols.h"
#import "CLADescriptionDetailCell.h"
#import "CLAMapViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <MapKit/MapKit.h>
#import "Image.h"
#import "UITextView+Utilities.h"
#import "CLAWebViewController.h"
#import "CLAWebPlayerController.h"
#import "UITableViewCell+Common.h"

#define EVENT @"event"

static NSString *webViewPage = 	@"<!DOCTYPE html> "
@"<html> "
@"<body> "
@"<iframe id=\"player\" type=\"text/html\" width=\"%i\" height=\"%i\" "
@"src=\"%@\" "
@"frameborder=\"0\"></iframe> "
@"</body> "
@"</html> ";

typedef enum
{
	kCLAHeaderDetailViewCellIndex,
	kCLAActionsDetailCellIndex,
	kCLAAddressDetailCellIndex,
	kCLADescriptionDetailCellIndex,
	kCLADetailCellsCount
	
} CLADetailViewCellIndex;

static NSString *const CLAHeaderDetailCellIdentifier		= @"CLAHeaderDetailCell";
static NSString *const CLAActionsDetailCellIdentifier		= @"CLAActionsDetailCell";
static NSString *const CLAAddressDetailCellIdentifier		= @"CLAAddressDetailCell";
static NSString *const CLADescriptionDetailCellIdentifier	= @"CLADescriptionDetailCell";

@interface CLADetailViewController ()
{
	CLAHeaderDetailCell *_headerDetailCell;
	NSMutableDictionary *_cellIndentifiers;
	NSMutableArray		*_cellHeights;
	NSInteger			_currentPage;
	NSArray				*_images;

	NSIndexPath *indexPathToMap;
	
	NSMutableArray *webPlayers;
	NSMutableDictionary *_cellSetupSelectors;
}

-(UITableViewCell *)setupHeaderCellOnIndexPath:(NSIndexPath *)indexPath;
-(UITableViewCell *)setupActionsCellOnIndexPath:(NSIndexPath *)indexPath;
-(UITableViewCell *)setupAddressCellOnIndexPath:(NSIndexPath *)indexPath;
-(UITableViewCell *)setupDescriptionCellOnIndexPath:(NSIndexPath *)indexPath;

-(void)registerTableviewNibs;
-(void)selectImage:(id)sender;

-(void)sendMail:(id)sender;
-(void)callPhone:(id)sender;
-(void)openBrowser:(id)sender;
-(void)setupButton:(UIButton *)button withImage:(UIImage *)image selector:(SEL)selector;
-(BOOL)isPoi;
-(BOOL)showActions;
-(void)setupCellIdentifies;
-(void)openYoutubeLink:(id)sender;
-(void)setupShareButton;
-(void)showShareMenu;

-(void)showAlertWithObject:(id)object;

-(void)shareOnSocialNetwork:(NSString *)socialNetwork;

//Social

-(void)setupAndPostToTwitter;
-(void)setupAndPostToFacebook;

@end

@implementation CLADetailViewController


-(id)initWithItem:(id<CLAItem>)item
{
	if (self = [super init])
	{
		self.item = item;
		webPlayers = [NSMutableArray array];
		
		_cellHeights	  = [NSMutableArray arrayWithCapacity:kCLADetailCellsCount];
		
		for (int i = 0; i < kCLADetailCellsCount; i++)
			[_cellHeights addObject:@0.0];
	}
	
	return self;
}

#pragma mark - View related methods


-(UITableView *)tableView
{
	return (UITableView *)self.view;
}

-(void)loadView
{
	self.view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	UIStatusBarStyle style = [[self.store userInterface][CLAAppDataStoreUIStatusBarStyleKey] integerValue];
	
	NSAssert(style >= 0 && style <= 1, @"Invalid status bar style %d", style);
	
	[[UIApplication sharedApplication] setStatusBarStyle:style];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

	[self.view setBackgroundColor:[self.store userInterface][CLAAppDataStoreUIBackgroundColorKey]];
	
	[self setupTableView:self.tableView withCellIdentifier:nil];
	
	[self registerTableviewNibs];
	
	[self setupTitleView];

	if (!self.skipList)
	{
		[self setupBackButton];
	}

	[self setupShareButton];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[(UILabel *)self.navigationItem.titleView setText:[self.item title]];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	for (CLAWebPlayerController *webPlayer in webPlayers)
	{
		[webPlayer.webView stopLoading];
		webPlayer.webView.delegate = nil;
	}
}

#pragma mark - UITableView datasource


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger addressDelta = (NSInteger)self.isPoi ? 0 : 1;
	NSInteger actionsDelta = (NSInteger)[self showActions] ? 0 : 1;

	return (NSInteger)kCLADetailCellsCount - addressDelta - actionsDelta;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SEL cellSetupSelector = NSSelectorFromString([_cellSetupSelectors objectForKey:@(indexPath.row)]);
	
	UITableViewCell *cell = [self performSelector:cellSetupSelector withObject:indexPath];
	
	[cell setShadowColor:(UIColor *)[self.store userInterface][CLAAppDataStoreUICellShadowColorKey]];

	return cell;
}

#pragma mark - UITableView delegate methods

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [_cellHeights[indexPath.row] floatValue];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPathToMap isEqual:indexPath])
	{
		CLAMapViewController *mapViewController = [[CLAMapViewController alloc] initDetailMap:YES];
		mapViewController.store		= self.store;
		mapViewController.appMaker	= self.appMaker;
		mapViewController.localizedStrings = self.localizedStrings;

		mapViewController.items = @[self.item];
		
		[self.navigationController pushViewController:mapViewController animated:YES];
	}
}

#pragma mark - helper methods

#pragma mark Setup Cells

-(UITableViewCell *)setupDescriptionCellOnIndexPath:(NSIndexPath *)indexPath
{
	CLADescriptionDetailCell *cell = (CLADescriptionDetailCell *)[self.tableView dequeueReusableCellWithIdentifier:CLADescriptionDetailCellIdentifier];
	
	cell.frame = CGRectMake(0.0, 0.0, cell.frame.size.width, 300.0);

	UIColor *backgroundColor	= [self.store userInterface][CLAAppDataStoreUIBoxDescriptionColorKey];
	UIColor *fontColor			= [self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontColorKey];
	CGFloat fontSize			= [[self.store userInterface][CLAAppDataStoreUIBoxFontSizeKey] floatValue];
	//NSString *fontName			= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	CGFloat fontInterline		= [[self.store userInterface][CLAAppDataStoreUIBoxFontInterlineKey] floatValue];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setLineSpacing:fontInterline];
	
	NSMutableAttributedString *textString = [[NSMutableAttributedString alloc] initWithString:self.item.detailText];
	[textString addAttribute:NSParagraphStyleAttributeName
					   value:paragraphStyle
					   range:NSMakeRange(0, textString.length)];

	cell.detailTextView.attributedText	= textString;
	cell.detailTextView.backgroundColor = backgroundColor;
	cell.detailTextView.font			= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontKey] size:fontSize];
	cell.detailTextView.textColor		= fontColor;
	
	textString = [[NSMutableAttributedString alloc] initWithString:[self.item title]];
	[textString addAttribute:NSParagraphStyleAttributeName
					   value:paragraphStyle
					   range:NSMakeRange(0, textString.length)];
	
	cell.titleTextView.attributedText	= textString;
	cell.titleTextView.backgroundColor	= [self.store userInterface][CLAAppDataStoreUIBoxTitleColorKey];
	cell.titleTextView.font				= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:fontSize];
	cell.titleTextView.textColor		= [self.store userInterface][CLAAppDataStoreUIBoxTitleFontColorKey];
	
	[cell setNeedsUpdateConstraints];

	return cell;

}

-(UITableViewCell *)setupHeaderCellOnIndexPath:(NSIndexPath *)indexPath
{
	static NSSortDescriptor *defaultOrdering;
	
	if (!defaultOrdering)
	{
		defaultOrdering = [NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES];
	}
	
	NSMutableArray *emptyImages = [NSMutableArray array];
	NSMutableArray *emptyViews	= [NSMutableArray array];

	_headerDetailCell = (CLAHeaderDetailCell *)[self.tableView dequeueReusableCellWithIdentifier:CLAHeaderDetailCellIdentifier];
	
//	[_headerDetailCell setTitle:[self.item title]];
	
	_images = [[self.item.images allObjects] sortedArrayUsingDescriptors:@[defaultOrdering]];
	
	float scrollviewWidth	= CGRectGetWidth(_headerDetailCell.scrollView.frame);
	float scrollviewHeigth	= CGRectGetHeight(_headerDetailCell.scrollView.frame);
	
	_headerDetailCell.scrollView.contentSize	= CGSizeMake([_images count] * scrollviewWidth, scrollviewHeigth);
	_headerDetailCell.scrollView.pagingEnabled	= YES;
	_headerDetailCell.scrollView.delegate		= self;


	for (int i = 0; i < [_images count]; i++)
	{
		id <CLAImage> imageItem = _images[i];
		
		CGRect nextFrame = CGRectMake(i * scrollviewWidth, 0.0, scrollviewWidth, scrollviewHeigth);
		
		if ([@"video" isEqualToString:[imageItem type]])
		{
			NSInteger videoLocation = [[imageItem videoURL] rangeOfString:@"?v="].location;
			
			if (NSNotFound == videoLocation)
			{
				videoLocation = [[imageItem videoURL] rangeOfString:@"be/"].location;
				
				if (NSNotFound == videoLocation)
					continue;
			}
			
			NSString *videoIDString = [[imageItem videoURL] substringWithRange:NSMakeRange(videoLocation + 3, 11)];
			NSString *youtubeURL = [@"http://www.youtube.com/embed/" stringByAppendingString:videoIDString];
			
			NSString *pageToLoad = [NSString stringWithFormat:webViewPage, (NSInteger)nextFrame.size.width, (NSInteger)nextFrame.size.height, youtubeURL];
			
			CLAWebPlayerController *webPlayer = [[CLAWebPlayerController alloc] init];
			[webPlayers addObject:webPlayer];
			
			UIWebView *webView = [[UIWebView alloc] initWithFrame:nextFrame];
			webPlayer.view  = webView;
			
			webView.backgroundColor = [UIColor blackColor];
			webView.delegate = self;
			webView.alpha = 0.001;
			[webView.scrollView setScrollEnabled:NO];
			[webView.scrollView setContentInset:UIEdgeInsetsMake(-8, -8, 0, 0)];
			
			[_headerDetailCell.scrollView addSubview:webView];
			[webView loadHTMLString:pageToLoad baseURL:[NSURL URLWithString:@"http://www.youtube.com"]];
			
		}
		else
		{
			UIImageView *imageView = [[UIImageView alloc] initWithFrame:nextFrame];

			[_headerDetailCell.scrollView addSubview:imageView];
			imageView.image = imageItem.image;
			
			if (!imageItem.image && i > 0)
			{
				[emptyImages addObject:[(NSManagedObject *)imageItem objectID]];
				[emptyViews addObject:imageView];
			}
		}
	}
	
	if ([emptyImages count] > 0)
	{
		[self.store fetchImagesForImageObjects:emptyImages completion:^(NSError *error)
		 {
			 if (error)
			 {
				 NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento dei dati! (Code: %i)", error.code];
				 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errore!"
																 message:alertMessage
																delegate:nil
													   cancelButtonTitle:@"Continua"
													   otherButtonTitles:nil];
				 [alert show];
			 }
			 
			 for (NSInteger i = 0; i < [emptyImages count]; i++)
			 {
				 UIImageView *imageView			= [emptyViews objectAtIndex:i];
				 NSManagedObjectID *objectID	= [emptyImages objectAtIndex:i];
				 Image* image					= (Image *)[self.store.context objectWithID:objectID];

				 CATransition *transition = [CATransition animation];
				 transition.type = kCATransitionFade;
				 [imageView.layer addAnimation:transition forKey:nil];
				 
				 imageView.image = [image image];
			 }
			 
			 
		 }];
	}

	[_headerDetailCell.pageControl setNumberOfPages:[_images count]];
	[_headerDetailCell.pageControl addTarget:self action:@selector(selectImage:) forControlEvents:UIControlEventValueChanged];
	
	return _headerDetailCell;
}

-(UITableViewCell *)setupActionsCellOnIndexPath:(NSIndexPath *)indexPath
{

	CLAActionsDetailCell *cell = (CLAActionsDetailCell *)[self.tableView dequeueReusableCellWithIdentifier:CLAActionsDetailCellIdentifier];
	
	NSString *fontName			= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	UIColor *textColor			= [self.store userInterface][CLAAppDataStoreUIActionCellTintColorKey];
	UIColor *disabledTextColor	= [textColor colorWithAlphaComponent:0.5];
	CGFloat fontSize			= [[self.store userInterface][CLAAppDataStoreUIActionFontSizeKey] floatValue];
	
	cell.tintColor				= [self.store userInterface][CLAAppDataStoreUIActionCellTintColorKey];
	
	UIColor *backColor	= [self.store userInterface][CLAAppDataStoreUIActionCellColorKey];
	UIColor *boxColor	= [self.store userInterface][CLAAppDataStoreUIBackgroundColorKey];
	
	UIFont *font = [UIFont fontWithName:fontName size:fontSize];

	NSString *gotoWebSite = [self.localizedStrings localizedStringForString:@"Go to website"];
	
	UIImage *webImage = [[UIImage imageNamed:@"web"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	[self setupButton:cell.mailButton withImage:webImage selector:@selector(openBrowser:)];
	[cell.mailButton setTitle:gotoWebSite forState:UIControlStateNormal];
	[cell.mailButton setTitleColor:textColor forState:UIControlStateNormal];
	[cell.mailButton setTitleColor:disabledTextColor forState:UIControlStateDisabled];
	[cell.mailButton.titleLabel setFont:font];
	cell.mailButton.backgroundColor = backColor;
	
	if (!self.item.urlAddress)
	{
		cell.mailButton.enabled = NO;
	}
	

	NSString *call = [self.localizedStrings localizedStringForString:@"Call"];
	
	UIImage *callImage = [[UIImage imageNamed:@"chiama"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	[self setupButton:cell.phoneButton withImage:callImage selector:@selector(callPhone:)];
	[cell.phoneButton setTitle:call forState:UIControlStateNormal];
	[cell.phoneButton setTitleColor:textColor forState:UIControlStateNormal];
	[cell.phoneButton setTitleColor:disabledTextColor forState:UIControlStateDisabled];
	[cell.phoneButton.titleLabel setFont:font];
	cell.phoneButton.backgroundColor = backColor;
	
	if (!self.item.phoneNumber)
	{
		cell.phoneButton.enabled = NO;
	}
	
	[cell setBackviewColor:boxColor];
	
	return cell;
	
}

-(UITableViewCell *)setupAddressCellOnIndexPath:(NSIndexPath *)indexPath
{

	CLAAddressDetailCell *cell = (CLAAddressDetailCell *)[self.tableView dequeueReusableCellWithIdentifier:CLAAddressDetailCellIdentifier];

	CLLocation *end	= [[CLLocation alloc] initWithLatitude:self.item.coordinate.latitude longitude:self.item.coordinate.longitude];
	
	CLLocationDistance distance = [self.store.lastPosition distanceFromLocation:end];
	
	NSString *subTitle;
	
	if ([self.item.subType isEqualToString:EVENT])
	{
		static NSDateFormatter *formatter;
		
		if (!formatter)
		{
			formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"dd LLLL 'alle' HH:mm"];
		}
		
		subTitle = [formatter stringFromDate:self.item.date];
	}
	else
	{
		if (distance / 1000.0 > 1)
		{
			subTitle = [NSString stringWithFormat:@"%1.0f Km", (distance / 1000.0)];
		}
		else
		{
			subTitle = [NSString stringWithFormat:@"%1.0f m", distance];
		}
	}
	
	[cell setTitle:self.item.address];
	[cell setSubtitle:subTitle];
	
	[cell setBackgroundImage:[UIImage imageNamed:@"buttonsBack-single"]];
	[cell setDetailImage:[UIImage imageNamed:@"newMapIcon"]];
	[cell setAccessoryImage:[UIImage imageNamed:@"arrowMap"]];
	
	UILabel *titleLabel		= [cell valueForKey:@"_titleLabel"];
	UILabel *subtitleLabel	= [cell valueForKey:@"_subtitleLabel"];
	NSString *fontName		= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	
	titleLabel.font			= [UIFont fontWithName:fontName size:14.];
	subtitleLabel.font		= [UIFont fontWithName:fontName size:10.];
	
	indexPathToMap = indexPath;
	
	return cell;
}

-(void)selectImage:(id)sender
{
	UIPageControl *pageControl = (UIPageControl *)sender;
	_currentPage = pageControl.currentPage;
	
	float scrollviewWidth	= CGRectGetWidth(_headerDetailCell.scrollView.frame);
	
	CGPoint offset = CGPointMake(_currentPage * scrollviewWidth, 0.0);
	
	[_headerDetailCell.scrollView setContentOffset:offset animated:YES];
}

- (void)setupCellIdentifies
{
	//		NSArray *indexes = @[@(kCLAHeaderDetailViewCellIndex), @(kCLAActionsDetailCellIndex), @(kCLAAddressDetailCellIndex), @(kCLADescriptionDetailCellIndex)];
	//		NSArray *keys	 = @[CLAHeaderDetailCellIdentifier, CLAActionsDetailCellIdentifier, CLAAddressDetailCellIdentifier, CLADescriptionDetailCellIdentifier];
	
	NSInteger cellIndex		= 0;
	NSMutableArray *indexes		= [NSMutableArray arrayWithObject:@(cellIndex)];
	NSMutableArray *keys		= [NSMutableArray arrayWithObject:CLAHeaderDetailCellIdentifier];
	NSMutableArray *selectors	= [NSMutableArray arrayWithObject:NSStringFromSelector(@selector(setupHeaderCellOnIndexPath:))];
	
	if ([self showActions])
	{
		[indexes addObject:@(++cellIndex)];
		[selectors addObject:NSStringFromSelector(@selector(setupActionsCellOnIndexPath:))];
		[keys addObject:CLAActionsDetailCellIdentifier];
	}
	
	if (self.isPoi)
	{
		[indexes addObject:@(++cellIndex)];
		[selectors addObject:NSStringFromSelector(@selector(setupAddressCellOnIndexPath:))];
		[keys addObject:CLAAddressDetailCellIdentifier];
	}
	
	[indexes addObject:@(++cellIndex)];
	[selectors addObject:NSStringFromSelector(@selector(setupDescriptionCellOnIndexPath:))];
	[keys addObject:CLADescriptionDetailCellIdentifier];
	
	_cellIndentifiers = [NSMutableDictionary dictionaryWithObjects:indexes
														   forKeys:keys];
	
	_cellSetupSelectors	 = [NSMutableDictionary dictionaryWithObjects:selectors
															  forKeys:indexes];
}

-(void)registerTableviewNibs
{
	
	[self setupCellIdentifies];
	
	for (NSString *identifier in _cellIndentifiers)
	{
		NSInteger currentCellIndex = [_cellIndentifiers[identifier] integerValue];
		
		UINib *nib					= [UINib nibWithNibName:identifier bundle:nil];
		UITableView *cell			= [nib instantiateWithOwner:nil options:nil][0];
		
		CGFloat cellHeightFromNib = CGRectGetHeight(cell.frame);
		
		if ([CLADescriptionDetailCellIdentifier isEqualToString:identifier])
		{
			CLADescriptionDetailCell *descCell = (CLADescriptionDetailCell *)cell;
			
			CGFloat textViewHeight			= CGRectGetHeight(descCell.detailTextView.frame);
			CGFloat margin = (cellHeightFromNib - textViewHeight - descCell.titleTextView.contentSize.height) / 2.0;
			
			CGFloat fontSize				= [[self.store userInterface][CLAAppDataStoreUIBoxFontSizeKey] floatValue];
			//NSString *fontName				= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
			CGFloat fontInterline		= [[self.store userInterface][CLAAppDataStoreUIBoxFontInterlineKey] floatValue];
			
			NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
			[paragraphStyle setLineSpacing:fontInterline];
			
			NSMutableAttributedString *textString = [[NSMutableAttributedString alloc] initWithString:self.item.detailText];
			[textString addAttribute:NSParagraphStyleAttributeName
							   value:paragraphStyle
							   range:NSMakeRange(0, textString.length)];

			descCell.detailTextView.attributedText = textString;
			descCell.detailTextView.font	= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontKey] size:fontSize];
			
			textString = [[NSMutableAttributedString alloc] initWithString:[self.item title]];
			[textString addAttribute:NSParagraphStyleAttributeName
							   value:paragraphStyle
							   range:NSMakeRange(0, textString.length)];

			descCell.titleTextView.attributedText	= textString;
			descCell.titleTextView.font				= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:fontSize];

			cellHeightFromNib = 2 * margin + [descCell.titleTextView heightForTextView] + [descCell.detailTextView heightForTextView];

		}
		
		[_cellHeights replaceObjectAtIndex:currentCellIndex
								withObject:[NSNumber numberWithFloat:cellHeightFromNib]];
		
		[self.tableView registerNib:nib forCellReuseIdentifier:identifier];
	}
	

}

#pragma mark Utilities

-(BOOL)isPoi
{
	CLLocationCoordinate2D coordinate = [self.item coordinate];
	
	return coordinate.latitude > 0.0 && coordinate.longitude > 0.0 && [self.item address];
}

-(BOOL)showActions
{
	return self.item.urlAddress || self.item.phoneNumber;
}

-(void)openYoutubeLink:(id)sender
{
	id <CLAImage> selectedVideo = _images[_currentPage];
	
	NSAssert([selectedVideo videoURL], @"Should have a url video!");
	
	NSURL *youtubeUrl = [NSURL URLWithString:[selectedVideo videoURL]];
	
	[[UIApplication sharedApplication] openURL:youtubeUrl];
}

-(void)setupShareButton
{
	UIImage *shareImage = [self.store userInterface][CLAAppDataStoreUIShareIconKey];
	
	NSArray *shareButton = [self barButtonItemForSelector:@selector(showShareMenu)
														withImage:shareImage];
	
	self.navigationItem.rightBarButtonItems = shareButton;
}

-(void)showShareMenu
{
	UIActionSheet *share = [[UIActionSheet alloc] initWithTitle:nil
													   delegate:self
											  cancelButtonTitle:@"Annulla"
										 destructiveButtonTitle:nil
											  otherButtonTitles:@"Twitter", @"Facebook", nil];
	[share showInView:self.view];
	
}

-(void)showAlertWithObject:(id)object
{

	 NSString *title;
	 NSString *message;
	 
	 if ([object isKindOfClass:[NSError class]])
	 {
		 title = @"Errore!";
		 message = [(NSError *)object localizedDescription];
	 }
	 else if ([object isKindOfClass:[NSString class]])
	 {
		 title = @"Operazione Completata!";
		 message = (NSString *)object;
	 }
	 else
	 {
		 NSException *exception = [[NSException alloc] initWithName:@"Application Error"
															 reason:@"Invalid object in 'showAlertWithObject'"
														   userInfo:nil];
		 
		 @throw exception;
	 }
	 
	 
	 
	 UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
												  message:message
												 delegate:nil
										cancelButtonTitle:@"Continua"
										otherButtonTitles:nil];
	 [av show];

}

#pragma mark - UIWebVIewDelegate

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
	[UIView animateWithDuration:0.2
						  delay:0.3
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^(){webView.alpha = 1.0;}
					 completion:nil];
}

#pragma mark - Facebook & Twitter setup

-(void)shareOnSocialNetwork:(NSString *)socialNetwork
{
	//if ([SLComposeViewController isAvailableForServiceType:socialNetwork])
	__weak id weakSelf = self;
	
	SLComposeViewController *shareController = [SLComposeViewController composeViewControllerForServiceType:socialNetwork];

	[shareController setInitialText:[NSString stringWithFormat:@"Sto guardando %@ tramite FUNtv!", self.item.title]];
	[shareController addImage:self.item.mainImage];
	[shareController addURL:[NSURL URLWithString:@"http://www.funtv.it"]];
#warning change url
	
	shareController.completionHandler = ^(SLComposeViewControllerResult result)
	{
		[weakSelf dismissViewControllerAnimated:YES completion:nil];
	};
	
	[self presentViewController:shareController animated:YES completion:nil];

}

-(void)setupAndPostToTwitter
{
	
	[self shareOnSocialNetwork:SLServiceTypeTwitter];
	
//	ACAccountStore *store		= [[ACAccountStore alloc] init];
//	ACAccountType *twitterType	= [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
//	
//	void (^completionBlock)(BOOL, NSError *) = ^void(BOOL granted, NSError *error)
//	{
//		if (error)
//		{
//			NSLog(@"Errore durante l'accesso a Twitter: %@", error);
//
//			[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//								   withObject:error
//								waitUntilDone:NO];
//		}
//		else if (granted)
//		{
//			ACAccount *twitter = [[store accountsWithAccountType:twitterType] lastObject];
//
//			if (!twitter)
//			{
//				NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Nessun account Twitter configurato!"]};
//				
//				NSError *err = [NSError errorWithDomain:@"CLADetailViewControllerDomain"
//												   code:999
//											   userInfo:userInfo];
//				[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//									   withObject:err
//									waitUntilDone:NO];
//				
//				return;
//			}
//			
//			NSURL *postURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"];
//			
//			SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
//													requestMethod:SLRequestMethodPOST
//															  URL:postURL
//													   parameters:nil];
//			request.account = twitter;
//			
//			[request addMultipartData:[[self.item title] dataUsingEncoding:NSUTF8StringEncoding]
//							 withName:@"status"
//								 type:@"multipart/form-data"
//							 filename:nil];
//			
//			[request addMultipartData:UIImageJPEGRepresentation([self.item mainImage], 1.0)
//							 withName:@"media"
//								 type:@"image/jpeg"
//							 filename:[(id <CLAImage>)_images[0] fileName]];
//			
//			
//			[request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
//			{
//				if (error)
//				{
//					NSLog(@"Errore durante l'accesso a Twitter: %@", error);
//
//					[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//										   withObject:error
//										waitUntilDone:NO];
//				}
//				else if ([urlResponse statusCode] != 200)
//				{
//					NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Errore durante l'accesso a Twitter! (Code: %i)", [urlResponse statusCode]]};
//
//					NSLog(@"%@", [NSString stringWithUTF8String:[responseData bytes]]);
//					
//					NSError *err = [NSError errorWithDomain:@"CLADetailViewControllerDomain"
//														 code:[urlResponse statusCode]
//													 userInfo:userInfo];
//
//					[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//										   withObject:err
//										waitUntilDone:NO];
//				}
//				else
//				{
//					NSString *success = @"Il tuo messaggio è stato pubblicato su Twitter!";
//					
//					[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//										   withObject:success
//										waitUntilDone:NO];
//				}
//			}];
//			
//			
//		}
//	};
//	
//	[store requestAccessToAccountsWithType:twitterType
//								   options:nil
//								completion:completionBlock];
	
}


-(void)setupAndPostToFacebook
{
	
	[self shareOnSocialNetwork:SLServiceTypeFacebook];

//	ACAccountStore *store		= [[ACAccountStore alloc] init];
//	ACAccountType *facebookType	= [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
//	
//	NSDictionary *options		= @{ACFacebookAppIdKey			: @"237006269793490",
//									ACFacebookAudienceKey		: ACFacebookAudienceEveryone,
//									ACFacebookPermissionsKey	: @[@"email"]};
//	
//	void (^completionBlock)(BOOL, NSError *) = ^(BOOL granted, NSError *error)
//	{
//		if (error)
//		{
//			NSLog(@"%@", error);
//			
//			if (6 == [error code])
//			{
//				NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Nessun account Facebook configurato!"]};
//				
//				error = [NSError errorWithDomain:[error domain]
//											code:6
//										userInfo:userInfo];
//			}
//			
//			[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//								   withObject:error
//								waitUntilDone:NO];
//		}
//		else if	(granted)
//		{
//			ACAccount *facebook = [[store accountsWithAccountType:facebookType] lastObject];
//			
//			if (!facebook)
//			{
//				NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Nessun account Facebook configurato!"]};
//				
//				NSError *err = [NSError errorWithDomain:@"CLADetailViewControllerDomain"
//												   code:999
//											   userInfo:userInfo];
//				[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//									   withObject:err
//									waitUntilDone:NO];
//				
//				return;
//			}
//			
//			NSDictionary *options = @{ACFacebookAudienceKey		: ACFacebookAudienceEveryone,
//									  ACFacebookPermissionsKey	: @[@"publish_stream"],
//									  ACFacebookAppIdKey		: @"237006269793490"
//									  };
//
//			void (^streamBlock)(BOOL, NSError *) = ^(BOOL granted, NSError *error)
//			{
//				
//				if (error)
//				{
//					NSLog(@"%@", error);
//
//					[self performSelectorOnMainThread:@selector(showAlertWithObject:)
//										   withObject:error
//										waitUntilDone:NO];
//				}
//				else if (granted)
//				{
//					NSURL *postURL = [NSURL URLWithString:@"https://graph.facebook.com/me/photos"];
//					
//					NSDictionary *parameters = @{@"message" : [self.item title]};
//					
//					SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
//															requestMethod:SLRequestMethodPOST
//																	  URL:postURL
//															   parameters:parameters];
//					
//					request.account = facebook;
//					
//					[request addMultipartData:UIImagePNGRepresentation([self.item mainImage])
//									 withName:@"source"
//										 type:@"multipart/form-data"
//									 filename:@"Image"];
//
//					void (^completionHandler)(NSData *, NSHTTPURLResponse *, NSError *) = ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
//					 {
//						 if (error)
//						 {
//							 NSLog(@"Errore durante l'accesso a Facebook: %@", error);
//							 
//							 [self performSelectorOnMainThread:@selector(showAlertWithObject:)
//													withObject:error
//												 waitUntilDone:NO];
//						 }
//						 else if ([urlResponse statusCode] != 200)
//						 {
//							 NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Errore durante l'accesso a Facebook! (Code: %i)", [urlResponse statusCode]]};
//
//							 NSLog(@"%@", [NSString stringWithUTF8String:[responseData bytes]]);
//							 
//							 NSError *err = [NSError errorWithDomain:@"CLADetailViewControllerDomain"
//																code:[urlResponse statusCode]
//															userInfo:userInfo];
//							 
//							 [self performSelectorOnMainThread:@selector(showAlertWithObject:)
//													withObject:err
//												 waitUntilDone:NO];
//						 }
//						 else
//						 {
//							 NSString *success = @"Il tuo messaggio è stato pubblicato su Facebook!";
//							 
//							 [self performSelectorOnMainThread:@selector(showAlertWithObject:)
//													withObject:success
//												 waitUntilDone:NO];
//						 }
//					
//					 };
//					
//					[request performRequestWithHandler:completionHandler];
//				}
//				
//			};
//			
//			
//			[store requestAccessToAccountsWithType:facebookType
//										   options:options
//										completion:streamBlock];
//			
//		}
//		
//	};
//	
//	[store requestAccessToAccountsWithType:facebookType
//								   options:options
//								completion:completionBlock];
}

#pragma mark - UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 0:
			[self setupAndPostToTwitter];
			break;
		case 1:
			[self setupAndPostToFacebook];
			break;
		default:
			break;
	}
}


#pragma mark - UIScrollView delegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	CGFloat pageWidth = CGRectGetWidth(_headerDetailCell.scrollView.frame);
    NSUInteger page = floor((_headerDetailCell.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _headerDetailCell.pageControl.currentPage = page;
	_currentPage = page;
}


#pragma mark - Button actions methods

-(void)openBrowser:(id)sender
{
	
	CLAWebViewController *browser = [[CLAWebViewController alloc] init];
	
	browser.store		= self.store;
	browser.appMaker	= self.appMaker;
	browser.item		= self.item;
	
	
	NSURL *url = [NSURL URLWithString:self.item.urlAddress];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	
	[browser.webView loadRequest:request];
	
	[self.navigationController pushViewController:browser animated:YES];
	
}

-(void)sendMail:(id)sender
{
	MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
	
	composer.mailComposeDelegate = self;
	
	[composer setToRecipients:@[[self.item eMailAddress]]];
	
	[self presentViewController:composer animated:YES completion:nil];
	
}

-(void)callPhone:(id)sender
{
	NSURL *phoneNumber = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", [self.item phoneNumber]]];
	
	[[UIApplication sharedApplication] openURL:phoneNumber];
}

-(void)setupButton:(UIButton *)button withImage:(UIImage *)image selector:(SEL)selector
{
	[button setImage:image forState:UIControlStateNormal];

	[button setImageEdgeInsets:UIEdgeInsetsMake(0., 0., 0., 10.)];
	
	if (selector)
	{
		[button setEnabled:YES];
		[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	}
}

#pragma mark - MFMailComposeViewControllerDelegate methods

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
