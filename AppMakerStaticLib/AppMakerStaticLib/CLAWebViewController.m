//
//  CLAWebViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 23/01/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAWebViewController.h"
#import "CLALocalizedStringsStore.h"


@interface CLAWebViewController ()

-(void)showShareMenu;

@end

@implementation CLAWebViewController

-(void)loadView
{
	self.view = [[UIWebView alloc] initWithFrame:CGRectZero];
}

-(UIWebView *)webView
{
	return (UIWebView *)self.view;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	[self setupBackButton];
	[self setupTitleView];

	self.webView.delegate			= self;
	
	UIImage *shareImage = [self.store userInterface][CLAAppDataStoreUIShareIconKey];
	
	NSArray *shareButton = [self barButtonItemForSelector:@selector(showShareMenu)
												withImage:shareImage];
	
	self.navigationItem.rightBarButtonItems = shareButton;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (self.item)
	{
		[(UILabel *)self.navigationItem.titleView setText:[self.item title]];
	}
	else
	{
		[(UILabel *)self.navigationItem.titleView setText:self.headerTitle];
	}

}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	self.webView.delegate = nil;
}

-(void)showShareMenu
{
	NSString *openInSafari = [self.localizedStrings localizedStringForString:@"Open in Safari"];

	UIActionSheet *share = [[UIActionSheet alloc] initWithTitle:nil
													   delegate:self
											  cancelButtonTitle:@"Annulla"
										 destructiveButtonTitle:nil
											  otherButtonTitles:openInSafari, nil];
	[share showInView:self.view];
}

#pragma mark UIWebViewDelegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	self.webView.scalesPageToFit	= YES;
	
	return YES;
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
														message:[NSString stringWithFormat:@"%@: indirizzo non valido", self.webView.request.URL.absoluteString]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles: nil];
	
	[alertView show];
	
	NSLog(@"%@", error);
}

#pragma mark UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (0 == buttonIndex)
	{
		[[UIApplication sharedApplication] openURL:self.webView.request.URL];
	}

}

@end
