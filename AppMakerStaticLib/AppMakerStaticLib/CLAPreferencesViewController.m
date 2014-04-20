//
//  CLAPreferencesViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 03/02/14.
//  Copyright (c) 2014 Christian Lao. All rights reserved.
//

#import "CLAPreferencesViewController.h"
#import "CLAModelProtocols.h"
#import "CLAAppDataStore.h"
#import "CLAPreferences.h"
#import "SVProgressHUD.h"
#import "CLALocalizedStringsStore.h"

@interface CLAPreferencesViewController ()

@property (nonatomic) NSArray *languages;

-(void)savePreferences:(id)sender;

-(void)reloadContentsFromNotification:(NSNotification *)notification;
-(void)reloadContents;

-(BOOL)preferredLanguageHasChanged;

-(void)setupLabels;

@end

@implementation CLAPreferencesViewController

-(UITableView *)tableView
{
	return (UITableView *)self.view;
}

-(void)loadView
{
	self.view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
}

-(void)viewDidLoad
{
	[self setupTableView:self.tableView withCellIdentifier:nil];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
	self.tableView.backgroundColor = [self.store userInterface][CLAAppDataStoreUIBackgroundColorKey];

	[self setupTitleView];
	
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save"
																   style:UIBarButtonItemStylePlain
																  target:self
																  action:@selector(savePreferences:)];
	
	//saveButton.tintColor		= [self.store userInterface][CLAAppDataStoreUIHeaderFontColorKey];

	self.navigationItem.rightBarButtonItem = saveButton;
	
	
	[self setupLabels];

}

-(void)viewWillAppear:(BOOL)animated
{
	[self reloadContents];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadContentsFromNotification:)
												 name:CLAAppDataStoreDidFetchNewData
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadContentsFromNotification:)
												 name:CLAAppDataStoreDidFailToFetchNewData
											   object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDelegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.languages count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
	
	NSString *fontName		= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	CGFloat fontSize		= [[self.store userInterface][CLAAppDataStoreUIMenuFontSizeKey] floatValue];
	
	cell.textLabel.font			= [UIFont fontWithName:fontName size:fontSize];
	cell.textLabel.textColor	= [self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontColorKey];
	cell.tintColor				= [self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontColorKey];
	cell.backgroundColor		= [self.store userInterface][CLAAppDataStoreUIBoxDescriptionColorKey];
	
	id <CLALocale> language = self.languages[indexPath.row];

	cell.textLabel.text			= [language languageDescription];
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	NSString *preferredLanguage = [self.preferences valueForKey:CLAPreferredLanguageCodeKey];
	
	if ([[language languageCode] isEqualToString:preferredLanguage])
	{
		[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 60.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	UILabel *label		= [[UILabel alloc] initWithFrame:CGRectZero];
	
	NSString *fontName		= [self.store userInterface][CLAAppDataStoreUIFontNameKey];
	CGFloat fontSize		= [[self.store userInterface][CLAAppDataStoreUIMenuFontSizeKey] floatValue];
	
	label.textAlignment = NSTextAlignmentCenter;
	label.font			= [UIFont fontWithName:fontName size:fontSize];
	label.textColor		= [self.store userInterface][CLAAppDataStoreUIForegroundColorKey];
	
	NSString *chooseLanguage = [self.localizedStrings localizedStringForString:@"Choose language:"];
	
	label.text = chooseLanguage;
	
	return label;
}

#pragma mark - UITableViewDelegate

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
	
	[oldCell setAccessoryType:UITableViewCellAccessoryNone];
	
	return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
	
	[selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
	
	if ([self preferredLanguageHasChanged])
	{
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}
	else
	{
		[self.navigationItem.rightBarButtonItem setEnabled:NO];
	}
}

#pragma mark - Private Methods

-(void)savePreferences:(id)sender
{
	if ([self preferredLanguageHasChanged])
	{
		id <CLALocale> selectedLanguage = self.languages[[self.tableView indexPathForSelectedRow].row];
		
		[self.preferences setValue:[selectedLanguage languageCode] forKey:CLAPreferredLanguageCodeKey];
		
		NSString *loading = [self.localizedStrings localizedStringForString:@"Loading..."];
		
		[SVProgressHUD showWithStatus:loading maskType:SVProgressHUDMaskTypeGradient];
		
		[self.store fetchRemoteDataWithTimeout:0 skipCaching:YES];
	}
}

-(void)reloadContentsFromNotification:(NSNotification *)notification
{

	NSError *error = [notification userInfo][CLAAppDataStoreFetchErrorKey];
	
	if (error)
	{
		[self reloadContents];

		NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento dei dati! (Code: %i)", error.code];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errore!"
														message:alertMessage
													   delegate:nil
											  cancelButtonTitle:@"Continua"
											  otherButtonTitles:nil];
		[alert show];
		
		return;
		
	}
	
	[self.store preFetchMainImagesWithCompletionBlock:^(NSError *error)
	 {
		 [self reloadContents];

		 if (error)
		 {
			 NSString *alertMessage = [NSString stringWithFormat:@"Errore nel caricamento delle immagini! (Code: %i)", error.code];
			 
			 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errore!"
																 message:alertMessage
																delegate:nil
													   cancelButtonTitle:@"Continua"
													   otherButtonTitles:nil];
			 [alertView show];
		 }
		 
	 }];


}

-(void)reloadContents
{
	self.languages			= [self.store.locales copy];
	[self.navigationItem.rightBarButtonItem setEnabled:NO];
	
	[self setupLabels];
	
	[self.tableView reloadData];
	
	if ([SVProgressHUD isVisible])
	{
		[SVProgressHUD dismiss];
	}
}

-(BOOL)preferredLanguageHasChanged
{
	BOOL changed = NO;
	
	id <CLALocale> selectedLanguage = self.languages[[self.tableView indexPathForSelectedRow].row];
	NSString *preferredLanguage		= [self.preferences valueForKey:CLAPreferredLanguageCodeKey];
	
	NSAssert(selectedLanguage, @"Huh?");
	
	if (![[selectedLanguage languageCode] isEqualToString:preferredLanguage])
		changed = YES;

	return changed;
}

-(void)setupLabels
{
	NSString *preferences	= [self.localizedStrings localizedStringForString:@"Preferences"];
	NSString *save			= [self.localizedStrings localizedStringForString:@"Save"];
	
	[(UILabel *)self.navigationItem.titleView setText:preferences];
	
	self.navigationItem.rightBarButtonItem.title = save;
}

@end
