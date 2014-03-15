//
//  CLAQRCodeReaderViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 15/03/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAQRCodeReaderViewController.h"
#import "CLAWebViewController.h"

@interface CLAQRCodeReaderViewController ()
{
	AVCaptureSession *_session;
	AVCaptureVideoPreviewLayer *_previewLayer;
	BOOL _retryReadingQRCode;
}

-(void)setupAVSession;

@end

@implementation CLAQRCodeReaderViewController

- (void)setupAVSession
{
	_session = [[AVCaptureSession alloc] init];
	
	_session.sessionPreset = AVCaptureSessionPresetHigh;
	
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	NSError *error;
	
	AVCaptureDeviceInput *input		= [AVCaptureDeviceInput deviceInputWithDevice:device
																		error:&error];
	
	AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];

	if (input)
	{
		[_session addInput:input];
		[_session addOutput:output];
		
		[output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
		[output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
		
		_previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];

		_previewLayer.bounds		= [self.view bounds];
		_previewLayer.videoGravity	= AVLayerVideoGravityResizeAspectFill;
		_previewLayer.position		= self.view.layer.position;
		
		[self.view.layer addSublayer:_previewLayer];
	}
	else
	{
		NSLog(@"%@", error);
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errore!"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"Ok"
											  otherButtonTitles:nil];
		[alert show];
		
	}
}

-(void)viewDidLoad
{
	[super viewDidLoad];

	[self setupAVSession];
	
	[self setupTitleView];
	
	[(UILabel *)self.navigationItem.titleView setText:@"QR Reader"];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[_session startRunning];
}

-(void)dealloc
{
	[[[_session outputs] firstObject] setMetadataObjectsDelegate:nil queue:nil];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
	for (AVMetadataObject *metaData in metadataObjects)
	{
		if ([metaData.type isEqualToString:AVMetadataObjectTypeQRCode])
		{
			[_session stopRunning];
	
			AVMetadataMachineReadableCodeObject *readableMetaData = (AVMetadataMachineReadableCodeObject *)metaData;
			
			NSString *decodedString =[readableMetaData stringValue];
			
			NSDataDetector *dataDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
			
			NSRange linkRange = NSMakeRange(0, decodedString.length);
			
			if (1 == [dataDetector numberOfMatchesInString:decodedString options:0 range:linkRange])
			{
				if (![decodedString hasPrefix:@"http"] && ![decodedString hasPrefix:@"https"])
				{
					decodedString = [@"http://" stringByAppendingString:decodedString];
				}
				
				NSURL *decodedURL = [NSURL URLWithString:decodedString];
				NSURLRequest *request = [NSURLRequest requestWithURL:decodedURL];
				
				CLAWebViewController *webViewController = [[CLAWebViewController alloc] init];
				
				webViewController.appMaker		= self.appMaker;
				webViewController.store			= self.store;
				webViewController.headerTitle	= [decodedURL host];
				
				[(UIWebView *)webViewController.view loadRequest:request];
				
				[self.navigationController pushViewController:webViewController animated:YES];
				
			}
			else
			{

				_retryReadingQRCode = YES;
				NSString *error = [NSString stringWithFormat:@"%@ non è un URL corretto!", decodedString];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errore!"
																message:error
															   delegate:self
													  cancelButtonTitle:@"Ok"
													  otherButtonTitles:nil];
				[alert show];
			}
			
			break;
		}
	}
}

#pragma mark UIAlerViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (_retryReadingQRCode)
	{
		_retryReadingQRCode = NO;
		[_session startRunning];
	}
}

@end
