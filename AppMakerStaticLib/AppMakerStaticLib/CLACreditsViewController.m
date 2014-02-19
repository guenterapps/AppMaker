//
//  CLACreditsViewController.m
//  AppMakerStaticLib
//
//  Created by Christian Lao on 29/12/13.
//  Copyright (c) 2013 Christian Lao. All rights reserved.
//

#import "CLACreditsViewController.h"
#import "CLADescriptionDetailCell.h"
#import "UIColor-Expanded.h"
#import "UITextView+Utilities.h"

static NSString *const cellIdentifier		= @"CLADescriptionDetailCell";
static NSString *const CLATitleKey			= @"CLATitleKey";
static NSString *const CLADescriptionKey	= @"CLADescriptionKey";

@interface CLACreditsViewController ()

@property (nonatomic) NSArray	*textData;
@property (nonatomic) NSMutableArray *cellHeights;

-(void)setupTableViewCells;

@end

@implementation CLACreditsViewController

-(UITableView *)tableView
{
	return (UITableView *)self.view;
}

-(void)loadView
{
	self.view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor clearColor];
	
	[self setupTitleView];

	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	
	[self setupTableView:self.tableView withCellIdentifier:cellIdentifier];
	
	[(UILabel *)self.navigationItem.titleView setText:@"Credits"];
	
	self.textData		= [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"credits" ofType:@"plist"]];
	
	NSAssert(self.textData, @"Should load the credits file!");

	self.cellHeights	= [NSMutableArray array];
	
	[self setupTableViewCells];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CLADescriptionDetailCell *cell = (CLADescriptionDetailCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	cell.detailTextView.text	= self.textData[indexPath.row][CLADescriptionKey];
	
	cell.frame = CGRectMake(0.0, 0.0, cell.frame.size.width, 300.0);
	
	UIColor *backgroundColor	= [self.store userInterface][CLAAppDataStoreUIBoxColorKey];
	UIColor *fontColor			= [self.store userInterface][CLAAppDataStoreUIBoxFontColorKey];
	CGFloat fontSize			= [[self.store userInterface][CLAAppDataStoreUIBoxFontSizeKey] floatValue];
	
	cell.detailTextView.backgroundColor = backgroundColor;
	cell.detailTextView.font			= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontKey] size:fontSize];
	cell.detailTextView.textColor		= fontColor;

	cell.titleTextView.backgroundColor	= [UIColor whiteColor];
	
	[cell setShadowColor:(UIColor *)[self.store userInterface][CLAAppDataStoreUICellShadowColorKey]];
	
	UIFont *font			= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:fontSize];
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.textData[indexPath.row][CLATitleKey]];
		
	[attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [attributedString length])];
	[attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [attributedString length])];
	
	if (indexPath.row == 1)
	{
		UIColor *redColor = [UIColor colorWithRed:1.0 green:(66./255.) blue:0. alpha:1.];
		[attributedString addAttribute:NSForegroundColorAttributeName value:redColor range:NSMakeRange(14, 1)];
	}
		
	cell.titleTextView.attributedText = attributedString;
	
	
	return cell;
}

#pragma mark - UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self.cellHeights[indexPath.row] floatValue];
}


#pragma mark - Private Methods

-(void)setupTableViewCells
{
	UINib *nib					= [UINib nibWithNibName:cellIdentifier bundle:nil];
	UITableView *cell			= [nib instantiateWithOwner:nil options:nil][0];
	
	CGFloat cellHeightFromNib	= CGRectGetHeight(cell.frame);

	CLADescriptionDetailCell *descCell = (CLADescriptionDetailCell *)cell;
		
	CGFloat textViewHeight			= CGRectGetHeight(descCell.detailTextView.frame);
	CGFloat margin					= (cellHeightFromNib - textViewHeight - descCell.titleTextView.contentSize.height) / 2.0;
		
	for (int i = 0; i < 2; ++i)
	{
		CGFloat fontSize				= [[self.store userInterface][CLAAppDataStoreUIBoxFontSizeKey] floatValue];
		
		descCell.detailTextView.font	= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIBoxDescriptionFontKey] size:fontSize];
		descCell.detailTextView.text	= self.textData[i][CLADescriptionKey];
		
		descCell.titleTextView.font		= [UIFont fontWithName:[self.store userInterface][CLAAppDataStoreUIFontNameKey] size:fontSize];
		descCell.titleTextView.text		= self.textData[i][CLATitleKey];
		
		cellHeightFromNib = 2 * margin + [descCell.detailTextView heightForTextView] + [descCell.titleTextView heightForTextView];
		
		[self.cellHeights addObject:@(cellHeightFromNib)];
	}

}


@end
